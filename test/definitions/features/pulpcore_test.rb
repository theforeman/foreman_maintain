require 'test_helper'

describe Features::Pulpcore do
  include DefinitionsTestHelper

  subject { Features::Pulpcore.new }

  describe '.cli' do
    it 'returns hash result when getting JSON reply' do
      subject.expects(:execute!).with('pulp --format json status',
        merge_stderr: false).returns('{"versions": []}')
      expected = { 'versions' => [] }
      assert_equal expected, subject.cli('status')
    end

    it 'passes on ExecutionError' do
      subject.expects(:execute!).with('pulp --format json status', merge_stderr: false).
        raises(ForemanMaintain::Error::ExecutionError.new('', 1, '', ''))
      assert_raises(ForemanMaintain::Error::ExecutionError) do
        subject.cli('status')
      end
    end
  end

  describe '.running_tasks' do
    it 'returns an empty list when there are no tasks' do
      subject.expects(:execute!).
        with('pulp --format json task list --state-in running --state-in canceling',
          merge_stderr: false).
        returns('[]')
      assert_empty subject.running_tasks
    end

    it 'returns an empty list when pulp cli failed' do
      subject.expects(:execute!).
        with('pulp --format json task list --state-in running --state-in canceling',
          merge_stderr: false).
        raises(ForemanMaintain::Error::ExecutionError.new('', 1, '', ''))
      assert_empty subject.running_tasks
    end

    it 'returns an empty list when pulp cli returned unparseable json' do
      subject.expects(:execute!).
        with('pulp --format json task list --state-in running --state-in canceling',
          merge_stderr: false).
        returns('JZon')
      assert_empty subject.running_tasks
    end
  end

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
