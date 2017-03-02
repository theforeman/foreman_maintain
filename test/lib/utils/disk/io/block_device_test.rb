require 'test_helper'

module ForemanMaintain
  describe Utils::Disk::IO::BlockDevice do
    let(:default_dir) { '/var' }
    let(:device_name) { '/dev/root' }
    let(:stdout) { 'Timing buffered disk reads: 1024 MB in  3.00 seconds = 99.99 MB/sec' }

    before do
      @bdio = described_class.new(default_dir, device_name)
    end

    it 'should initialze with dir and name' do
      assert_equal(default_dir, @bdio.dir)
      assert_equal(device_name, @bdio.name)
    end

    it 'returns read_speed and executes hdparm only once' do
      @bdio.expects(:hdparm).once.returns(stdout)

      refute_nil(@bdio.read_speed)
      assert_equal(99, @bdio.read_speed)
    end

    it 'returns unit and executes hdparm only once' do
      @bdio.expects(:hdparm).once.returns(stdout)

      refute_nil(@bdio.unit)
      assert_equal('MB/sec', @bdio.unit)
    end
  end
end
