require 'test_helper'
describe Checks::Disk::AvailableSpacePostgresql13 do
  include DefinitionsTestHelper
  include UnitTestHelper

  let(:check) { described_class.new }

  before do
    assume_feature_present(:instance) do |feature|
      feature.any_instance.stubs(:postgresql_local?).returns(true)
    end
  end

  it 'executes successfully for disks with sufficient space' do
    check.stubs(:psql_12_consumed_space).returns(1_024)
    check.stubs(:psql_13_available_space).returns(2_048)

    step = run_step(check)
    assert_empty(step.output)
    assert_equal(:success, step.status)
  end

  it 'prints warnings for for disks with insufficient space' do
    check.stubs(:psql_12_consumed_space).returns(10_240)
    check.stubs(:psql_13_available_space).returns(2_048)

    step = run_step(check)

    warning = "PostgreSQL will be upgraded from 12 to 13. \n"\
      "During the upgrade a backup is created in /var/lib/pgsql/data-old "\
      "and requires at least 10240 MiB free space."
    assert_equal(warning, step.output)
    assert_equal(:fail, step.status)
  end
end
