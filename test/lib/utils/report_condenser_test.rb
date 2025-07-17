require 'test_helper'

module ForemanMaintain
  describe Utils::ReportCondenser do
    include UnitTestHelper

    describe '#condense_report' do
      it 'condenses the report' do
        data = {
          'advisor_on_prem_remediations_count' => 10,
          'rhel_ai_workload_host_count' => 20,
        }
        result = Utils::ReportCondenser.condense_report(data)
        _(result['advisor_on_prem_remediations_count']).must_equal 10
        _(result['rhel_ai_workload_host_count']).must_equal 20
      end
    end

    describe '#aggregate_host_count' do
      it 'aggregates the host count numbers' do
        data = {
          'hosts_by_os_count|RedHat' => 20,
          'hosts_by_os_count|CentOS' => 10,
          'hosts_by_family_count|Redhat' => 30,
        }
        result = Utils::ReportCondenser.aggregate_host_count(data)
        expected = {
          'host_rhel_count' => 20,
          'host_redhat_without_rhel_count' => 10,
          'host_other_count' => 0,
        }
        _(result).must_equal(expected)
      end
    end

    describe '#aggregate_image_mode_host_count' do
      it 'aggregates the image mode host count' do
        data = {
          'image_mode_hosts_by_os_count|RedHat' => 20,
          'image_mode_hosts_by_os_count|CentOS' => 10,
        }
        result = Utils::ReportCondenser.aggregate_image_mode_host_count(data)
        _(result).must_equal({ 'image_mode_host_count' => 30 })
      end
    end

    describe '#aggregate_networking_metrics' do
      it 'aggregates the networking metrics' do
        data = {
          'subnet_ipv6_count' => 10,
          'hosts_with_ipv6only_interface_count' => 20,
        }
        result = Utils::ReportCondenser.aggregate_networking_metrics(data)
        _(result).must_equal({ 'use_dualstack' => false, 'use_ipv6' => true })
      end
    end
  end
end
