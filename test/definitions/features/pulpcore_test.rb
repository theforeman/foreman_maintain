require 'test_helper'

describe Features::Pulpcore do
  include DefinitionsTestHelper

  subject { Features::Pulpcore.new }

  describe '.cli_available?' do
    it 'recognizes server with CLI' do
      File.expects(:exist?).with('/etc/pulp/cli.toml').returns(true)
      assert subject.cli_available?
    end

    it 'recognizes proxy without CLI' do
      File.expects(:exist?).with('/etc/pulp/cli.toml').returns(false)
      refute subject.cli_available?
    end
  end
end
