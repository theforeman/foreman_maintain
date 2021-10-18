module Checks
  class CheckHttpsProxies < ForemanMaintain::Check
    metadata do
      label :https_proxies
      for_feature :foreman_database
      description 'Check for HTTPS proxies from the database'
      manual_detection
    end

    def run
      https_proxies = find_https_proxies
      unless https_proxies.empty?
        https_proxy_names = https_proxies.map { |proxy| proxy['name'] }
        question = "Syncing repositories through an 'HTTP Proxy' that uses the HTTPS\n"\
                    "protocol is not supported directly with Satellite 6.10.\n"\
                    "The following proxies use HTTPS: #{https_proxy_names.join(', ')}.\n"\
                    "For a suggested solution see https://access.redhat.com/solutions/6414991\n"\
                    'Continue upgrade?'
        answer = ask_decision(question, actions_msg: 'y(yes), q(quit)')
        abort! if answer != :yes
      end
    end

    def find_https_proxies
      feature(:foreman_database).query(self.class.query_to_get_https_proxies)
    end

    def self.query_to_get_https_proxies
      <<-SQL
        SELECT \"http_proxies\".* FROM \"http_proxies\" WHERE (http_proxies.url ilike 'https://%')
      SQL
    end
  end
end
