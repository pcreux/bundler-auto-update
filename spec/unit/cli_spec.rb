require 'spec_helper'

describe CLI do
  describe "#test_command" do
    context "when -c option is passed" do
      it "should extract the test command from arguments" do
        expect(CLI.new(%w(-c rake test)).test_command).to eq('rake test')
      end
    end

    context "when no -c option" do
      it "should return nil" do
        expect(CLI.new(%w(--help meh)).test_command).to be_nil
        expect(CLI.new([]).test_command).to be_nil
      end
    end
  end
end
