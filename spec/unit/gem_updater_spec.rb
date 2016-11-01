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

    before do
      allow(gemfile).to receive(:locked_version_for).with('rails').
        and_return '3.0.0'
    end

    context "when no new version" do
      before do
        allow(gemfile).to receive(:available_versions_for).with('rails').
          and_return %w(3.0.0)
      end

      it "should return" do
        expect(gem_updater).not_to receive :update_gemfile
        expect(gem_updater).not_to receive :run_test_suite

        gem_updater.update(:patch)
      end
    end

    context "when new version" do
      before do
        allow(gemfile).to receive(:available_versions_for).with('rails').
          and_return %w(4.1.1 4.1.0 4.0.1 4.0.0 3.10.0 3.9.1 3.9.0 3.1.1 3.1.0 3.0.1 3.0.0)
      end

      context "when tests pass" do
        it "should commit new version and return true" do
          expect(gem_updater).to receive(:update_gemfile).and_return true
          expect(gem_updater).to receive(:run_test_suite).and_return true
          expect(gem_updater).to receive(:commit_new_version).and_return true
          expect(gem_updater).not_to receive(:revert_to_previous_version)

          expect(gem_updater.update(:patch)).to eq(true)
        end
      end

      context "when tests do not pass" do
        it "should revert to previous version and return false" do
          expect(gem_updater).to receive(:update_gemfile).and_return true
          expect(gem_updater).to receive(:run_test_suite).and_return false
          expect(gem_updater).not_to receive(:commit_new_version)
          expect(gem_updater).to receive(:revert_to_previous_version)

          expect(gem_updater.update(:patch)).to eq(false)
        end
      end

      context "when it fails to upgrade gem" do
        it "should revert to previous version and return false" do
          expect(gem_updater).to receive(:update_gemfile).and_return false
          expect(gem_updater).not_to receive(:run_test_suite)
          expect(gem_updater).not_to receive(:commit_new_version)
          expect(gem_updater).to receive(:revert_to_previous_version)

          expect(gem_updater.update(:patch)).to eq(false)
        end

      end

      context "when it fails to upgrade gem and only Gemfile is checked in" do
        it 'should revert only Gemfile' do
          expect(gem_updater).to receive(:update_gemfile).and_return false
          expect(CommandRunner).to receive(:system).
            with("git status | grep 'Gemfile.lock' > /dev/null").and_return false
          expect(CommandRunner).to receive(:system).
            with("git checkout Gemfile").and_return false

          gem_updater.update(:patch)
        end
      end

      context 'when new version is below locked version' do
        let(:gem) { Dependency.new('rails', '> 3.0.0', nil) }

        before do
          allow(gemfile).to receive(:locked_version_for).with('rails').
            and_return '3.1.0'
        end

        it 'should not attempt to update' do
          expect(gem_updater).not_to receive :update_gemfile
          expect(gem_updater).not_to receive :run_test_suite

          gem_updater.update(:patch)
        end
      end

      context "when new version below locked version, but not alphabetically" do
        let(:gem) { Dependency.new('rails', '> 3.9.0', nil) }

        before do
          allow(gemfile).to receive(:locked_version_for).with('rails').
            and_return '3.10.0'
        end

        it 'should not attempt to update' do
          expect(gem_updater).not_to receive :update_gemfile
          expect(gem_updater).not_to receive :run_test_suite

          gem_updater.update(:patch)
        end
      end

      context 'when there is no locked version' do
        let(:gem) { Dependency.new('rails', '3.0.0', nil) }

        before do
          allow(gemfile).to receive(:locked_version_for).with('rails').
            and_return nil
        end

        it 'should not attempt to update' do
          expect(gem_updater).not_to receive :update_gemfile
          expect(gem_updater).not_to receive :run_test_suite

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

  describe 'with a given set of remote gems' do
    let(:dependency) { Dependency.new 'rails', '2.1.1' }
    let(:gem_updater) { GemUpdater.new(dependency, gemfile, test_command) }
    before do
      allow(gemfile).to receive(:available_versions_for).with('rails').
        and_return %w(
          3.1.0 3.0.10 3.0.9 3.0.8 3.0.7 3.0.6 3.0.5 3.0.4 3.0.3 3.0.2 3.0.1
          3.0.0 2.3.14 2.3.12 2.3.11 2.3.10 2.3.9 2.3.8 2.3.7 2.3.6 2.3.5 2.3.4 2.3.3
          2.3.2 2.2.3 2.2.2 2.1.2 2.1.1 2.1.0 2.0.5 2.0.4 2.0.2 2.0.1 2.0.0 1.2.6 1.2.5
          1.2.4 1.2.3 1.2.2 1.2.1 1.2.0 1.1.6 1.1.5 1.1.4 1.1.3 1.1.2 1.1.1 1.1.0 1.0.0
          0.14.4 0.14.3 0.14.2 0.14.1 0.13.1 0.13.0 0.12.1 0.12.0 0.11.1 0.11.0 0.10.1
          0.10.0 0.9.5 0.9.4.1 0.9.4 0.9.3 0.9.2 0.9.1 0.9.0 0.8.5 0.8.0)
    end

    describe "#last_version" do

      it "should be 2.1.2 with :patch" do
        expect(gem_updater.last_version(:patch)).to eq('2.1.2')
      end

      it "should be 2.3.14 with :minor" do
        expect(gem_updater.last_version(:minor)).to eq('2.3.14')
      end

      it "should be 3.1.0 with :major" do
        expect(gem_updater.last_version(:major)).to eq('3.1.0')
      end

    end

    describe "#available_versions" do
      it "should return an array of available versions" do
        expect(gem_updater.available_versions).
          to eq %w(
            3.1.0 3.0.10 3.0.9 3.0.8 3.0.7 3.0.6 3.0.5 3.0.4 3.0.3 3.0.2 3.0.1
            3.0.0 2.3.14 2.3.12 2.3.11 2.3.10 2.3.9 2.3.8 2.3.7 2.3.6 2.3.5 2.3.4 2.3.3
            2.3.2 2.2.3 2.2.2 2.1.2 2.1.1 2.1.0 2.0.5 2.0.4 2.0.2 2.0.1 2.0.0 1.2.6 1.2.5
            1.2.4 1.2.3 1.2.2 1.2.1 1.2.0 1.1.6 1.1.5 1.1.4 1.1.3 1.1.2 1.1.1 1.1.0 1.0.0
            0.14.4 0.14.3 0.14.2 0.14.1 0.13.1 0.13.0 0.12.1 0.12.0 0.11.1 0.11.0 0.10.1
            0.10.0 0.9.5 0.9.4.1 0.9.4 0.9.3 0.9.2 0.9.1 0.9.0 0.8.5 0.8.0)
      end
    end
  end
end
