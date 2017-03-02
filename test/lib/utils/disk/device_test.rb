require 'test_helper'

module ForemanMaintain
  describe Utils::Disk::Device do
    let(:default_dir) { '/var' }
    let(:device_name) { '/dev/root' }

    before do
      described_class.any_instance.expects(:find_device).returns(device_name)
    end

    it 'device is externally_mounted initialize IO::Filesystem' do
      described_class.any_instance.expects(:externally_mounted?).returns(true)
      device = described_class.new(default_dir)
      file_system = device.io_device

      refute_nil file_system
      assert_equal 'ForemanMaintain::Utils::Disk::IO::FileSystem', file_system.class.name
    end

    it 'device is not externally_mounted initialize IO::BlockDevice' do
      described_class.any_instance.expects(:externally_mounted?).returns(false)
      device = described_class.new(default_dir)
      block_device = device.io_device

      refute_nil block_device
      assert_equal 'ForemanMaintain::Utils::Disk::IO::BlockDevice', block_device.class.name
    end

    it 'should initialze with dir, name and io_device' do
      io_obj = stub(:dir => default_dir, :name => device_name)
      described_class.any_instance.expects(:init_io_device).returns(io_obj)

      disk = described_class.new(default_dir)
      assert_equal(default_dir, disk.dir)
      assert_equal(device_name, disk.name)
      assert_equal(io_obj, disk.io_device)
    end
  end
end
