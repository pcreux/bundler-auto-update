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
      allow(gemfile).to receive(:read) { content }
      allow(gemfile).to receive(:write) { true }
    }
  end

  describe "#gems" do
    subject { gemfile.gems }

    context "when emtpy Gemfile" do
      let(:content) { "" }

      it { is_expected.to eq([]) }
    end

    context "when Gemfile contains 3 gems" do
      describe '#size' do
        subject { super().size }
        it { is_expected.to eq(3) }
      end

      describe "first gem" do
        subject { gemfile.gems.first }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('rails') }
        end

        describe '#version' do
          subject { super().version }
          it { is_expected.to eq('3.0.0') }
        end

        describe '#options' do
          subject { super().options }
          it { is_expected.to be_nil }
        end
      end

      describe "second gem" do
        subject { gemfile.gems[1] }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('shoulda-matchers') }
        end

        describe '#version' do
          subject { super().version }
          it { is_expected.to eq('~> 0.9') }
        end

        describe '#options' do
          subject { super().options }
          it { is_expected.to be_nil }
        end
      end

      describe "last gem" do
        subject { gemfile.gems[2] }

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('mysql') }
        end

        describe '#version' do
          subject { super().version }
          it { is_expected.to be_nil }
        end

        describe '#options' do
          subject { super().options }
          it { is_expected.to eq(':git => "git://...."') }
        end
      end
    end
  end # describe "#gems"

  describe "#update_gem" do
    it "should update the gem version in the Gemfile" do
      gemfile.update_gem(Dependency.new('rails', '3.1.0'))

      expect(gemfile.content).to include(%{gem 'rails',  "3.1.0"})
    end

    it "should write the new Gemfile" do
      expect(gemfile).to receive(:write)

      gemfile.update_gem(Dependency.new('rails', '3.1.0'))
    end

    it "should run 'bundle install' against the gem" do
      expect(CommandRunner).to receive(:system).with("bundle install") { true }
      expect(CommandRunner).not_to receive(:system).with("bundle update rails")

      gemfile.update_gem(Dependency.new('rails', '3.1.0'))
    end

    it "should run 'bundle update' against the gem when bundle install fails because a gem version is locked" do
      expect(CommandRunner).to receive(:system).with("bundle install").and_return false
      expect(CommandRunner).to receive(:system).with("bundle update rails").and_return true

      expect(gemfile.update_gem(Dependency.new('rails', '3.1.0'))).to eq(true)
    end
  end
end
