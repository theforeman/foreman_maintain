require 'test_helper'
describe Checks::Disk::Performance do
  include DefinitionsTestHelper
  include UnitTestHelper

  let(:check_disk_performance) { described_class.new }

  before do
    assume_feature_absent(:mongo)
    assume_feature_present(:pulp2)
    check_disk_performance.stubs(:default_dirs).returns(:pulp2 => '/var/lib/pulp')
  end

  it 'should confine existence of fio' do
    described_class.stubs(:execute?).with('which fio').returns(true)
    check_disk_performance.expects(:run)

    check_disk_performance.run
  end

  it 'executes successfully for disk with minimal speed' do
    assume_satellite_present do |feature_class|
      feature_class.any_instance.stubs(:at_least_version? => true)
    end
    check_disk_performance.stubs(:check_only_single_device?).returns(true)

    io_obj = MiniTest::Mock.new
    io_obj.expect(:read_speed, 90)
    io_obj.expect(:slow_disk_error_msg, 'Slow disk')
    io_obj.expect(:name, '/dev/sda')
    io_obj.expect(:dir, '/var/lib/pulp')
    io_obj.expect(:performance, '90 MB/sec')

    ForemanMaintain::Utils::Disk::Device.stubs(:new).returns(io_obj)

    step = run_step(check_disk_performance)
    assert_equal(:success, step.status)
    assert_empty(step.output)
  end

  it 'raise error if disk speed does not meet minimal requirement' do
    assume_satellite_present do |feature_class|
      feature_class.any_instance.stubs(:current_version => version('6.2.0'))
    end
    slow_speed = 59
    err_msg = 'Slow disk'

    check_disk_performance.stubs(:check_only_single_device?).returns(true)

    io_obj = MiniTest::Mock.new
    2.times { io_obj.expect(:read_speed, slow_speed) }
    io_obj.expect(:slow_disk_error_msg, err_msg)
    io_obj.expect(:name, '/dev/sda')
    io_obj.expect(:unit, 'MB/sec')
    io_obj.expect(:dir, '/var/lib/pulp')
    2.times { io_obj.expect(:performance, '90 MB/sec') }

    ForemanMaintain::Utils::Disk::Device.stubs(:new).returns(io_obj)

    step = run_step(check_disk_performance)
    assert_equal(:fail, step.status)
    assert_equal(err_msg, step.output)
  end

  it 'print warning if disk speed does not meet minimal requirement on Sat >= 6.3' do
    assume_satellite_present do |feature_class|
      feature_class.any_instance.stubs(:current_version => version('6.4.0'))
    end

    slow_speed = 59
    err_msg = 'Slow disk'
    warning_msg = "\nWARNING: Low disk speed might have a negative impact on the system.\n" \
                  'See https://access.redhat.com/solutions/3397771 before proceeding' \

    check_disk_performance.stubs(:check_only_single_device?).returns(true)

    io_obj = MiniTest::Mock.new
    2.times { io_obj.expect(:read_speed, slow_speed) }
    io_obj.expect(:slow_disk_error_msg, err_msg)
    io_obj.expect(:name, '/dev/sda')
    io_obj.expect(:unit, 'MB/sec')
    io_obj.expect(:dir, '/var/lib/pulp')
    2.times { io_obj.expect(:performance, '90 MB/sec') }

    ForemanMaintain::Utils::Disk::Device.stubs(:new).returns(io_obj)

    step = run_step(check_disk_performance)
    assert_equal(:warning, step.status)
    assert_equal(err_msg + warning_msg, step.output)
  end
end
