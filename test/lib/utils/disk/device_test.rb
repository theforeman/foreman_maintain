require 'test_helper'

module ForemanMaintain
  describe Utils::Disk::Device do
    include UnitTestHelper
    let(:default_dir) { '/var' }
    let(:device_name) { '/dev/root' }

    before do
      described_class.any_instance.expects(:find_device).returns(device_name)
    end

    it 'device is externally_mounted initialize IODevice' do
      described_class.any_instance.expects(:externally_mounted?).returns(true)
      device = described_class.new(default_dir)
      io_readings = device.io_device

      refute_nil io_readings
      assert_equal 'ForemanMaintain::Utils::Disk::IODevice', io_readings.class.name
    end

    it 'should initialze with dir, name and io_device' do
      io_obj = stub(:dir => default_dir)
      Utils::Disk::IODevice.expects(:new).returns(io_obj)

      disk = described_class.new(default_dir)

      assert_equal(default_dir, disk.dir)
      assert_equal(device_name, disk.name)
      assert_equal(io_obj, disk.io_device)
    end
  end
end
