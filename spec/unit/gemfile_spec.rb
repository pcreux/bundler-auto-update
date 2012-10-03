require 'spec_helper'

describe Gemfile do
  let(:content) { <<-EOF
source :rubygems

gem 'rails',  "3.0.0"
group :test do
  gem 'shoulda-matchers' , '~> 0.9' 
end
gem 'mysql', :git => "git://...."
EOF
}

  let(:gemfile) do
    Gemfile.new.tap { |gemfile|
      gemfile.stub!(:read) { content }
      gemfile.stub!(:write) { true }
    }
  end

  describe "#gems" do
    subject { gemfile.gems }

    context "when emtpy Gemfile" do
      let(:content) { "" }

      it { should == [] }
    end

    context "when Gemfile contains 3 gems" do
      its(:size) { should == 3 }

      describe "first gem" do
        subject { gemfile.gems.first }

        its(:name) { should == 'rails' }
        its(:version) { should == '3.0.0' }
        its(:options) { should be_nil }
      end

      describe "second gem" do
        subject { gemfile.gems[1] }

        its(:name) { should == 'shoulda-matchers' }
        its(:version) { should == '~> 0.9' }
        its(:options) { should be_nil }
      end

      describe "last gem" do
        subject { gemfile.gems[2] }

        its(:name) { should == 'mysql' }
        its(:version) { should be_nil }
        its(:options) { should == ':git => "git://...."' }
      end
    end
  end # describe "#gems"

  describe "#update_gem" do
    it "should update the gem version in the Gemfile" do
      gemfile.update_gem(Dependency.new('rails', '3.1.0'))

      gemfile.content.should include(%{gem 'rails',  "3.1.0"})
    end

    it "should write the new Gemfile" do
      gemfile.should_receive(:write)

      gemfile.update_gem(Dependency.new('rails', '3.1.0'))
    end

    it "should run 'bundle install' against the gem" do
      CommandRunner.should_receive(:system).with("bundle install") { true }
      CommandRunner.should_not_receive(:system).with("bundle update rails")

      gemfile.update_gem(Dependency.new('rails', '3.1.0'))
    end

    it "should run 'bundle update' against the gem when bundle install fails because a gem version is locked" do
      CommandRunner.should_receive(:system).with("bundle install").and_return false
      CommandRunner.should_receive(:system).with("bundle update rails").and_return true

      gemfile.update_gem(Dependency.new('rails', '3.1.0')).should == true
    end
  end
end
