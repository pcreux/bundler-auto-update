require 'spec_helper'

describe Dependency do
  let(:dependency) { Dependency.new 'rails', '2.1.1' }

  before do
    allow(dependency).to receive(:gem_remote_list_output) { <<-EOS

## REMOTE GEMS

rails (3.1.0 ruby, 3.0.10 ruby, 3.0.9 ruby, 3.0.8 ruby, 3.0.7 ruby, 3.0.6 ruby, 3.0.5 ruby, 3.0.4 ruby, 3.0.3 ruby, 3.0.2 ruby, 3.0.1 ruby, 3.0.0 ruby, 2.3.14 ruby, 2.3.12 ruby, 2.3.11 ruby, 2.3.10 ruby, 2.3.9 ruby, 2.3.8 ruby, 2.3.7 ruby, 2.3.6 ruby, 2.3.5 ruby, 2.3.4 ruby, 2.3.3 ruby, 2.3.2 ruby, 2.2.3 ruby, 2.2.2 ruby, 2.1.2 ruby, 2.1.1 ruby, 2.1.0 ruby, 2.0.5 ruby, 2.0.4 ruby, 2.0.2 ruby, 2.0.1 ruby, 2.0.0 ruby, 1.2.6 ruby, 1.2.5 ruby, 1.2.4 ruby, 1.2.3 ruby, 1.2.2 ruby, 1.2.1 ruby, 1.2.0 ruby, 1.1.6 ruby, 1.1.5 ruby, 1.1.4 ruby, 1.1.3 ruby, 1.1.2 ruby, 1.1.1 ruby, 1.1.0 ruby, 1.0.0 ruby, 0.14.4 ruby, 0.14.3 ruby, 0.14.2 ruby, 0.14.1 ruby, 0.13.1 ruby, 0.13.0 ruby, 0.12.1 ruby, 0.12.0 ruby, 0.11.1 ruby, 0.11.0 ruby, 0.10.1 ruby, 0.10.0 ruby, 0.9.5 ruby, 0.9.4.1 ruby, 0.9.4 ruby, 0.9.3 ruby, 0.9.2 ruby, 0.9.1 ruby, 0.9.0 ruby, 0.8.5 ruby, 0.8.0 ruby)
railsbros-thrift4rails (0.3.1, 0.2.0)
EOS
    }
  end

  describe "#last_version" do
    it "should be 2.1.2 with :patch" do
      expect(dependency.last_version(:patch)).to eq('2.1.2')
    end

    it "should be 2.3.14 with :minor" do
      expect(dependency.last_version(:minor)).to eq('2.3.14')
    end

    it "should be 3.1.0 with :major" do
      expect(dependency.last_version(:major)).to eq('3.1.0')
    end

  end

  describe "#available_versions" do
    it "should return an array of available versions" do
      expect(dependency.available_versions).to eq(%w(3.1.0 3.0.10 3.0.9 3.0.8 3.0.7 3.0.6 3.0.5 3.0.4 3.0.3 3.0.2 3.0.1 3.0.0 2.3.14 2.3.12 2.3.11 2.3.10 2.3.9 2.3.8 2.3.7 2.3.6 2.3.5 2.3.4 2.3.3 2.3.2 2.2.3 2.2.2 2.1.2 2.1.1 2.1.0 2.0.5 2.0.4 2.0.2 2.0.1 2.0.0 1.2.6 1.2.5 1.2.4 1.2.3 1.2.2 1.2.1 1.2.0 1.1.6 1.1.5 1.1.4 1.1.3 1.1.2 1.1.1 1.1.0 1.0.0 0.14.4 0.14.3 0.14.2 0.14.1 0.13.1 0.13.0 0.12.1 0.12.0 0.11.1 0.11.0 0.10.1 0.10.0 0.9.5 0.9.4 0.9.4 0.9.3 0.9.2 0.9.1 0.9.0 0.8.5 0.8.0))
    end
  end

end
