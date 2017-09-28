require 'test_helper'

describe Checks::DiskSpeedMinimal do
  include DefinitionsTestHelper

  let(:check_disk_io) { described_class.new }

  it 'should confine existence of hdparm and fio' do
    described_class.stubs(:execute?).with('which hdparm').returns(true)
    described_class.stubs(:execute?).with('which fio').returns(true)
    check_disk_io.expects(:run)

    check_disk_io.run
  end

  it 'executes successfully for disk with minimal speed' do
    check_disk_io.stubs(:check_only_single_device?).returns(true)
    assume_feature_present(:katello)

    io_obj = MiniTest::Mock.new
    io_obj.expect(:read_speed, 90)
    io_obj.expect(:slow_disk_error_msg, 'Slow disk')
    io_obj.expect(:name, '/dev/sda')

    ForemanMaintain::Utils::Disk::Device.stubs(:new).returns(io_obj)

    step = run_step(check_disk_io)
    assert_equal(:success, step.status)
    assert_empty(step.output)
  end

  it 'raise error if disk speed does not meet minimal requirement' do
    slow_speed = 79
    err_msg = 'Slow disk'

    check_disk_io.stubs(:check_only_single_device?).returns(true)
    assume_feature_present(:katello)

    io_obj = MiniTest::Mock.new
    2.times { io_obj.expect(:read_speed, slow_speed) }
    io_obj.expect(:slow_disk_error_msg, err_msg)
    io_obj.expect(:name, '/dev/sda')
    io_obj.expect(:unit, 'MB/sec')

    ForemanMaintain::Utils::Disk::Device.stubs(:new).returns(io_obj)

    step = run_step(check_disk_io)
    assert_equal(:fail, step.status)
    assert_equal(err_msg, step.output)
  end
end
