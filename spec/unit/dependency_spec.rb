require 'spec_helper'

describe Dependency do
  let(:dependency) { Dependency.new 'rails', '2.1.3' }

  describe "#major" do
    it "returns the major version" do
      expect(dependency.major).to eq('2')
    end
  end

  describe "#minor" do
    it "returns the minor version" do
      expect(dependency.minor).to eq('1')
    end
  end

  describe "#patch" do
    it "returns the patch version" do
      expect(dependency.patch).to eq('3')
    end
  end
end
