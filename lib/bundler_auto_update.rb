require "bundler_auto_update/version"
require 'bundler'

module Bundler
  module AutoUpdate
    class CLI
      def initialize(argv)
        @argv = argv
      end

      def run!
        Updater.new(test_command).auto_update!
      end

      # @return [String] Test command from @argv
      def test_command
        if @argv.first == '-c'
          @argv[1..-1].join(' ')
        end
      end
    end # class CLI

    class Updater
      DEFAULT_TEST_COMMAND = "rake"

      attr_reader :test_command

      def initialize(test_command = nil)
        @test_command = test_command || DEFAULT_TEST_COMMAND
      end

      def auto_update!
        gemfile.gems.each do |gem|
          GemUpdater.new(gem, gemfile, test_command).auto_update
        end
      end

      private

      def gemfile
        @gemfile ||= Gemfile.new
      end
    end

    class GemUpdater
      attr_reader :gem, :gemfile, :test_command

      def initialize(gem, gemfile, test_command)
        @gem, @gemfile, @test_command = gem, gemfile, test_command
      end

      # Attempt to update to patch, then to minor then to major versions.
      def auto_update
        if updatable?
          Logger.log "Updating #{gem.name}"
          update(:patch) and update(:minor) and update(:major)
        else
          Logger.log "#{gem.name} is not auto-updatable, passing it."
        end
      end

      # Update current gem to latest :version_type:, run test suite and commit new Gemfile
      # if successful.
      #
      # @param version_type :patch or :minor or :major
      # @return [Boolean] true on success or when already at latest version
      def update(version_type)
        new_version = last_version(version_type) 
        locked_version = gemfile.locked_version_for(gem.name)

        unless locked_version
          Logger.log_indent "Current gem not found in the lockfile. Passing this update."

          return true
        end

        if Gem::Version.new(new_version) <= Gem::Version.new(locked_version)
          Logger.log_indent "Current gem already at latest #{version_type} version. Passing this update."

          return true
        end

        Logger.log_indent "Updating to #{version_type} version #{new_version}"

        gem.version = new_version

        if update_gemfile and run_test_suite and commit_new_version
          true
        else
          revert_to_previous_version
          false
        end
      end

      # Return last version scoped at :version_type:.
      #
      # Example: last_version(:patch), returns the last patch version 
      # for the current major/minor version
      #
      # @return [String] last version. Ex: '1.2.3'
      #
      def last_version(version_type)
        case version_type
        when :patch
          available_versions.select { |v| v =~ /^#{gem.major}\.#{gem.minor}\D/ }.first
        when :minor
          available_versions.select { |v| v =~ /^#{gem.major}\./ }.first
        when :major
          available_versions.first
        else
          raise "Invalid version_type: #{version_type}"
        end
      end

      # @return true when the gem has a fixed version.
      def updatable?
        !!(gem.version =~ /^~?>? ?\d+\.\d+(\.\d+)?$/)
      end

      # Return an ordered array of all available versions.
      #
      # @return [Array] of [String].
      def available_versions
        gemfile.available_versions_for(gem.name)
      end

      private

      # Update gem version in Gemfile.
      #
      # @return true on success, false on failure.
      def update_gemfile
        if gemfile.update_gem(gem) 
          Logger.log_indent "Gemfile updated successfully."
          true
        else
          Logger.log_indent "Failed to update Gemfile."
          false
        end
      end

      # @return true on success, false on failure
      def run_test_suite
        Logger.log_indent "Running test suite"
        if CommandRunner.system test_command
          Logger.log_indent "Test suite ran successfully."
          true
        else
          Logger.log_indent "Test suite failed to run."
          false
        end
      end

      def commit_new_version
        Logger.log_indent "Committing changes"

        CommandRunner.system "git commit #{files_to_commit} -m 'Auto update #{gem.name} to version #{gem.version}'"
      end

      def files_to_commit
        @files_to_commit ||= if CommandRunner.system "git status | grep 'Gemfile.lock' > /dev/null"
                               "Gemfile Gemfile.lock"
                             else
                               "Gemfile"
                             end
      end

      def revert_to_previous_version
        Logger.log_indent "Reverting changes"
        CommandRunner.system "git checkout #{files_to_commit}"
        gemfile.reload!
      end

      def gem_remote_list_output
        @gem_remote_list_output ||= CommandRunner.run "gem list #{gem.name} -r -a"
      end
    end # class GemUpdater

    class Gemfile

      # Regex that matches a gem definition line.
      #
      # @return [RegEx] matching [_, name, _, version, _, options]
      def gem_line_regex(gem_name = '([\w-]+)')
        /^\s*gem\s*['"]#{gem_name}['"]\s*(,\s*['"](.+)['"])?\s*(,\s*(.*))?\n?$/
      end

      # @note This funky code parser could be replaced by a funky dsl re-implementation
      def gems
        gems = []

        content.dup.each_line do |l|
          if match = l.match(gem_line_regex)
            _, name, _, version, _, options = match.to_a
            gems << Dependency.new(name, version, options)
          end
        end

        gems
      end

      # Update Gemfile and run 'bundle update'
      def update_gem(gem)
        update_content(gem) and write and run_bundle_update(gem)
      end

      # @return [String] Gemfile content
      def content
        @content ||= read
      end

      # Reload Gemfile content
      def reload!
        @content = read
      end

      def locked_version_for(gem_name)
        spec = bundler_lockfile.specs.find { |it| it.name == gem_name }
        spec.version.to_s if spec
      end

      def available_versions_for(gem_name)
        dep = Bundler::Dependency.new(gem_name, nil)
        bundler_definition.index.search(dep).map(&:version).sort.reverse.map(&:to_s)
      end

      def bundler_definition
        @bundler_definition ||=
          Bundler::Definition.build('Gemfile', 'Gemfile.lock', true).tap do |dfn|
            dfn.resolve_remotely!
          end
      end

      def bundler_lockfile
        @bundler_lockfile ||= Bundler::LockfileParser.new(File.read 'Gemfile.lock')
      end

      private

      def update_content(gem)
        new_content = ""
        content.each_line do |l|
          if l =~ gem_line_regex(gem.name)
            l.gsub!(/\d+\.\d+\.\d+/, gem.version)
          end

          new_content += l
        end

        @content = new_content
      end

      # @return [String] Gemfile content read from filesystem
      def read
        File.read('Gemfile')
      end

      # Write content to Gemfile
      def write
        File.open('Gemfile', 'w') do |f|
          f.write(content)
        end
      end

      # Attempt to run 'bundle install' and fall back on running 'bundle update :gem'.
      #
      # @param [Dependency] gem The gem to update
      #
      # @return true on success, false on failure
      def run_bundle_update(gem)
        CommandRunner.system("bundle install") or CommandRunner.system("bundle update #{gem.name}")
      end
    end # class Gemfile

    class Logger
      def self.log(msg, prefix = "")
        puts prefix + msg
      end

      # Log with indentation:
      # "  - Log message"
      #
      def self.log_indent(msg)
        log(msg, "  - ")
      end

      # Log command:
      # "  > bundle update"
      #
      def self.log_cmd(msg)
        log(msg, "    > ")
      end
    end

    class Dependency
      attr_reader :name, :options, :major, :minor, :patch
      attr_accessor :version

      def initialize(name, version = nil, options = nil)
        @name, @version, @options = name, version, options

        # TODO: enhance support of > and ~> in versions
        @major, @minor, @patch = version[/\d+\.\d+(\.\d+)?/].split('.') if version
      end
    end # class Dependency

    class CommandRunner

      # Output the command about to run, and run it using system.
      #
      # @return true on success, false on failure
      def self.system(cmd)
        Logger.log_cmd cmd

        Kernel.system cmd
      end

      # Run a system command and return its output.
      def self.run(cmd)
        `#{cmd}`
      end
    end
  end # module AutoUpdate
end # module Bundler
