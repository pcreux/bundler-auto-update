require 'spec_helper'

describe GemUpdater do
  let(:gemfile) { Gemfile.new }
  let(:test_command) { '' }

  describe "auto_update" do

    context "when gem is updatable" do
      let(:gem_updater) { GemUpdater.new(Dependency.new('rails', '3.0.0'), gemfile, test_command) }

      it "should attempt to update to patch, minor and major" do
        expect(gem_updater).to receive(:update).with(:patch).and_return(true)
        expect(gem_updater).to receive(:update).with(:minor).and_return(false)
        expect(gem_updater).not_to receive(:update).with(:major)

        gem_updater.auto_update
      end
    end

    context "when gem is not updatable" do
      let(:gem_updater) { GemUpdater.new(Dependency.new('rake', '<0.9'), gemfile, test_command) }

      it "should not attempt to update it" do
        expect(gem_updater).not_to receive(:update)

        gem_updater.auto_update
      end
    end
  end # describe "auto_update"

  describe "#update" do
    let(:gem) { Dependency.new('rails', '3.0.0', nil) }
    let(:gem_updater) { GemUpdater.new(gem, gemfile, test_command) }

    context "when no new version" do
      it "should return" do
        expect(gem).to receive(:last_version).with(:patch) { gem.version }
        expect(gem_updater).not_to receive :update_gemfile
        expect(gem_updater).not_to receive :run_test_suite

        gem_updater.update(:patch)
      end
    end

    context "when new version" do
      context "when tests pass" do
        it "should commit new version and return true" do
          expect(gem).to receive(:last_version).with(:patch) { gem.version.next }
          expect(gem_updater).to receive(:update_gemfile).and_return true
          expect(gem_updater).to receive(:run_test_suite).and_return true
          expect(gem_updater).to receive(:commit_new_version).and_return true
          expect(gem_updater).not_to receive(:revert_to_previous_version)

          expect(gem_updater.update(:patch)).to eq(true)
        end
      end

      context "when tests do not pass" do
        it "should revert to previous version and return false" do
          expect(gem).to receive(:last_version).with(:patch) { gem.version.next }
          expect(gem_updater).to receive(:update_gemfile).and_return true
          expect(gem_updater).to receive(:run_test_suite).and_return false
          expect(gem_updater).not_to receive(:commit_new_version)
          expect(gem_updater).to receive(:revert_to_previous_version)

          expect(gem_updater.update(:patch)).to eq(false)
        end
      end

      context "when it fails to upgrade gem" do
        it "should revert to previous version and return false" do
          expect(gem).to receive(:last_version).with(:patch) { gem.version.next }
          expect(gem_updater).to receive(:update_gemfile).and_return false
          expect(gem_updater).not_to receive(:run_test_suite)
          expect(gem_updater).not_to receive(:commit_new_version)
          expect(gem_updater).to receive(:revert_to_previous_version)

          expect(gem_updater.update(:patch)).to eq(false)
        end

      end

      context "when it fails to upgrade gem and only Gemfile is checked in" do
        it 'should revert only Gemfile' do
          expect(gem).to receive(:last_version).with(:patch) { gem.version.next }
          expect(gem_updater).to receive(:update_gemfile).and_return false
          expect(CommandRunner).to receive(:system).
            with("git status | grep 'Gemfile.lock' > /dev/null").and_return false
          expect(CommandRunner).to receive(:system).
            with("git checkout Gemfile").and_return false

          gem_updater.update(:patch)
        end
      end
    end
  end # describe "#update"

  describe "updatable?" do
    [ "1.0.0", "> 1.0.0", "~> 1.0.0", "1.0", ].each do |version|
      it "should be updatable when version is #{version}" do
        dependency = Dependency.new('rails', version)
        expect(GemUpdater.new(dependency, nil, nil)).to be_updatable
      end
    end

    it "should be updatable when version is < 1.0.0" do
      dependency = Dependency.new('rails', '< 1.0.0')
      expect(GemUpdater.new(dependency, nil, nil)).not_to be_updatable
    end
  end


end

