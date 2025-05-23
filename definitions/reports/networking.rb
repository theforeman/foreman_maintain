require 'socket'

module Reports
  class Networking < ForemanMaintain::Report
    metadata do
      description 'Report information about networking'
    end

    def run
      subnet_counts_by_type
      hosts_by_address_family
      interfaces_by_address_family
      preference_settings
    end

    private

    # How many ipv4 subnets are defined in Foreman?
    # How many ipv6 subnets are defined in Foreman?
    def subnet_counts_by_type
      %w[Ipv4 Ipv6].each do |type|
        data_field("subnet_#{type.downcase}_count") do
          sql_count("subnets where type = 'Subnet::#{type}'")
        end
      end
    end

    # How many hosts in Foreman have an interface with an ipv4 address but no ipv6 address?
    # How many hosts in Foreman have an interface with no ipv4 address but an ipv6 address?
    # How many hosts in Foreman have an interface with both ipv4 and ipv6 addresses?
    def hosts_by_address_family
      { 'ipv4only': 'nics.ip IS NOT NULL AND nics.ip6 IS NULL',
        'ipv6only': 'nics.ip IS NULL AND nics.ip6 IS NOT NULL',
        'dualstack': 'nics.ip IS NOT NULL AND nics.ip6 IS NOT NULL' }.each do |kind, condition|
        query = <<~SQL
          hosts
          WHERE id IN (SELECT host_id FROM nics WHERE #{condition})
        SQL
        data_field("hosts_with_#{kind}_interface_count") { sql_count(query) }
      end
    end

    # How many of Foreman's interfaces:
    # - only have a non-loopback, non-multicast ipv4 address?
    # - only have a non-loopback, non-multicast, non-link-local ipv6 address?
    # - have a non-loopback, non-multicast ipv4 address
    #   as well as a non-loopback, non-multicast, non-link-local ipv6 address?
    def interfaces_by_address_family
      by_name = Socket.getifaddrs.group_by(&:name).transform_values { |addrs| addrs.map(&:addr) }
      with_ipv4, without_ipv4 = by_name.partition { |_name, addrs| relevant_ipv4?(addrs) }
      dualstack, ipv4_only = with_ipv4.partition { |_name, addrs| relevant_ipv6?(addrs) }
      ipv6_only = without_ipv4.select { |_name, addrs| relevant_ipv6?(addrs) }

      data_field("foreman_interfaces_ipv4only_count") { ipv4_only.count }
      data_field("foreman_interfaces_ipv6only_count") { ipv6_only.count }
      data_field("foreman_interfaces_dualstack_count") { dualstack.count }
    end

    def relevant_ipv4?(addrs)
      addrs.any? { |addr| addr.ipv4? && !(addr.ipv4_loopback? || addr.ipv4_multicast?) }
    end

    def relevant_ipv6?(addrs)
      addrs.any? do |addr|
        addr.ipv6? && !(addr.ipv6_loopback? || addr.ipv6_multicast? || addr.ipv6_linklocal?)
      end
    end

    def preference_settings
      %w[remote_execution_connect_by_ip_prefer_ipv6 discovery_prefer_ipv6].each do |setting|
        data_field("setting_#{setting}") do
          value = sql_setting(setting)
          value.nil? ? false : YAML.safe_load(value)
        end
      end
    end
  end
end
