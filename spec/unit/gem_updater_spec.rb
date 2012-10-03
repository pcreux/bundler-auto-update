require 'spec_helper'

describe GemUpdater do
  let(:gemfile) { Gemfile.new }
  let(:test_command) { '' }

  describe "auto_update" do

    context "when gem is updatable" do
      let(:gem_updater) { GemUpdater.new(Dependency.new('rails', '3.0.0'), gemfile, test_command) }

      it "should attempt to update to patch, minor and major" do
        gem_updater.should_receive(:update).with(:patch).and_return(true)
        gem_updater.should_receive(:update).with(:minor).and_return(false)
        gem_updater.should_not_receive(:update).with(:major)

        gem_updater.auto_update
      end
    end

    context "when gem is not updatable" do
      let(:gem_updater) { GemUpdater.new(Dependency.new('rake', '<0.9'), gemfile, test_command) }

      it "should not attempt to update it" do
        gem_updater.should_not_receive(:update)

        gem_updater.auto_update
      end
    end
  end # describe "auto_update"

  describe "#update" do
    let(:gem) { Dependency.new('rails', '3.0.0', nil) }
    let(:gem_updater) { GemUpdater.new(gem, gemfile, test_command) }

    context "when no new version" do
      it "should return" do
        gem.should_receive(:last_version).with(:patch) { gem.version }
        gem_updater.should_not_receive :update_gemfile
        gem_updater.should_not_receive :run_test_suite

        gem_updater.update(:patch)
      end
    end

    context "when new version" do
      context "when tests pass" do
        it "should commit new version and return true" do
          gem.should_receive(:last_version).with(:patch) { gem.version.next }
          gem_updater.should_receive(:update_gemfile).and_return true
          gem_updater.should_receive(:run_test_suite).and_return true
          gem_updater.should_receive(:commit_new_version).and_return true
          gem_updater.should_not_receive(:revert_to_previous_version)

          gem_updater.update(:patch).should == true
        end
      end

      context "when tests do not pass" do
        it "should revert to previous version and return false" do
          gem.should_receive(:last_version).with(:patch) { gem.version.next }
          gem_updater.should_receive(:update_gemfile).and_return true
          gem_updater.should_receive(:run_test_suite).and_return false
          gem_updater.should_not_receive(:commit_new_version)
          gem_updater.should_receive(:revert_to_previous_version)

          gem_updater.update(:patch).should == false
        end
      end

      context "when it fails to upgrade gem" do
        it "should revert to previous version and return false" do
          gem.should_receive(:last_version).with(:patch) { gem.version.next }
          gem_updater.should_receive(:update_gemfile).and_return false
          gem_updater.should_not_receive(:run_test_suite)
          gem_updater.should_not_receive(:commit_new_version)
          gem_updater.should_receive(:revert_to_previous_version)

          gem_updater.update(:patch).should == false
        end
      end
    end
  end # describe "#update"

  describe "updatable?" do
    [ "1.0.0", "> 1.0.0", "~> 1.0.0", "1.0", ].each do |version|
      it "should be updatable when version is #{version}" do
        dependency = Dependency.new('rails', version)
        GemUpdater.new(dependency, nil, nil).should be_updatable
      end
    end

    it "should be updatable when version is < 1.0.0" do
      dependency = Dependency.new('rails', '< 1.0.0')
      GemUpdater.new(dependency, nil, nil).should_not be_updatable
    end
  end


end

