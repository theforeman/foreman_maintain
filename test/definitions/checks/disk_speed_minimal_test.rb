require 'test_helper'

describe Checks::DiskSpeedMinimal do
  include DefinitionsTestHelper

  let(:check_disk_io) { described_class.new(nil) }

  it 'should confine existence of hdparm and fio' do
    described_class.stubs(:execute?).with('which hdparm').returns(true)
    described_class.stubs(:execute?).with('which fio').returns(true)
    check_disk_io.expects(:run)

    check_disk_io.run
  end

  it 'executes successfully for disk with minimal speed' do
    check_disk_io.stubs(:check_only_single_device?).returns(true)

    io_obj = mock(:read_speed => 90, :slow_disk_error_msg => 'Slow disk')
    ForemanMaintain::Utils::Disk::Device.stubs(:new).returns(io_obj)

    refute check_disk_io.run
  end

  it 'raise error if disk speed does not meet minimal requirement' do
    slow_speed = 79
    err_msg = 'Slow disk'

    check_disk_io.stubs(:check_only_single_device?).returns(true)
    io_obj = mock(:unit => 'MB/sec',
                  :slow_disk_error_msg => err_msg)
    io_obj.stubs(:read_speed).returns(slow_speed)
    ForemanMaintain::Utils::Disk::Device.stubs(:new).returns(io_obj)

    exception = assert_raises(ForemanMaintain::Check::Fail) { check_disk_io.run }
    assert_equal(err_msg, exception.message)
  end
end
