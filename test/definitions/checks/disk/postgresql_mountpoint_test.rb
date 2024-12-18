require 'test_helper'
describe Checks::Disk::PostgresqlMountpoint do
  include DefinitionsTestHelper
  include UnitTestHelper

  let(:check) { described_class.new }

  before do
    assume_feature_present(:instance) do |feature|
      feature.any_instance.stubs(:postgresql_local?).returns(true)
    end
    ForemanMaintain.stubs(:el?).returns(true)
  end

  it 'executes successfully for data on same disks' do
    check.stubs(:psql_dir_device).returns('/dev/mapper/foreman-postgresql')
    check.stubs(:psql_data_dir_device).returns('/dev/mapper/foreman-postgresql')

    step = run_step(check)
    assert_empty(step.output)
    assert_equal(:success, step.status)
  end

  it 'prints warnings for data on separate disk' do
    check.stubs(:psql_dir_device).returns('/dev/mapper/foreman-root')
    check.stubs(:psql_data_dir_device).returns('/dev/mapper/foreman-postgresql')

    step = run_step(check)

    warning = <<~MSG
      PostgreSQL data (/var/lib/pgsql/data) is on a different device than /var/lib/pgsql.
      This is not supported and breaks PostgreSQL upgrades.
      Please ensure PostgreSQL data is on the same mountpoint as the /var/lib/pgsql.
    MSG
    assert_equal(warning, step.output)
    assert_equal(:fail, step.status)
  end
end
