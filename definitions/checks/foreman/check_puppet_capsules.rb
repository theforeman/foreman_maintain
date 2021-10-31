module Checks
  class CheckPuppetCapsules < ForemanMaintain::Check
    metadata do
      label :puppet_capsules
      for_feature :foreman_database
      description 'Check for Puppet capsules from the database'
      manual_detection
    end

    def run
      puppet_proxies = find_puppet_proxies.reject { |proxy| local_proxy?(proxy['url']) }
      unless puppet_proxies.empty?
        names = puppet_proxies.map { |proxy| proxy['name'] }
        print('You have proxies with Puppet feature enabled, '\
              "please disable Puppet on all proxies first.\n"\
              "The following proxies have Puppet feature: #{names.join(', ')}.")
        abort!
      end
    end

    def find_puppet_proxies
      feature(:foreman_database).query(puppet_proxies_query)
    end

    private

    def local_proxy?(url)
      URI.parse(url).hostname.casecmp(hostname) == 0
    end

    def puppet_proxies_query
      <<-SQL
        SELECT \"smart_proxies\".*
          FROM \"smart_proxies\"
            INNER JOIN \"smart_proxy_features\"
              ON \"smart_proxies\".\"id\" = \"smart_proxy_features\".\"smart_proxy_id\"
            INNER JOIN \"features\"
              ON \"features\".\"id\" = \"smart_proxy_features\".\"feature_id\"
          WHERE \"features\".\"name\" = 'Puppet'
      SQL
    end
  end
end
