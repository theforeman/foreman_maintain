require 'test_helper'

class FakeSystem
  include ForemanMaintain::Concerns::OsFacts
end

module ForemanMaintain
  describe Concerns::OsFacts do
    let(:system) { FakeSystem.new }

    it 'should report memory from /proc/meminfo' do
      File.expects(:read).with('/proc/meminfo').returns('MemTotal:       32594200 kB')

      assert_equal '32594200', system.memory
    end

    it 'should report CPU cores from nproc' do
      system.expects(:execute).with('nproc').returns('2')

      assert_equal '2', system.cpu_cores
    end
  end
end
