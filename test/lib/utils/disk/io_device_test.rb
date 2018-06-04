require 'test_helper'

module ForemanMaintain
  describe Utils::Disk::IODevice do
    include UnitTestHelper
    let(:default_dir) { '/var' }

    it 'should initialze with dir' do
      fio = described_class.new(default_dir)
      assert_equal(default_dir, fio.dir)
    end

    before do
      @fio = described_class.new(default_dir)
    end

    it 'instance should initialze with dir' do
      assert_equal(default_dir, @fio.dir)
    end

    it 'returns read_speed and executes fio only once' do
      @fio.expects(:fio).once.returns(99 * 1024)

      refute_nil(@fio.read_speed)
      assert_equal(99, @fio.read_speed)
    end

    it 'returns unit and executes fio only once' do
      @fio.expects(:fio).never

      refute_nil(@fio.unit)
      assert_equal('MB/sec', @fio.unit)
    end
  end
end
