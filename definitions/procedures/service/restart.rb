require 'procedures/service/base'

module Procedures::Service
  class Restart < Base
    metadata do
      description 'Restart applicable services'
      Base.common_params(self)
      param :wait_for_server_response,
        'Wait for server ping to return successfully before terminating'
    end

    RETRIES_FOR_SERVICES_RESTART = 5
    PING_RETRY_INTERVAL = 30

    def run
      run_service_action('restart', common_options.merge(:include_sockets => true))
      server_ping_retry if @wait_for_server_response
    end

    def server_ping_retry
      with_spinner('Checking server response') do |spinner|
        RETRIES_FOR_SERVICES_RESTART.times do |retry_count|
          spinner.update retry_message(retry_count)
          response = feature(:instance).ping
          if response.success?
            spinner.update 'Server responded successfully!'
            break
          elsif retry_count < (RETRIES_FOR_SERVICES_RESTART - 1)
            puts "\n#{response.message}"
            apply_sleep_before_retry(spinner)
          else
            raise 'Server response check failed!'
          end
        end
      end
    end

    def retry_message(retry_count)
      "Try #{retry_count + 1}/#{RETRIES_FOR_SERVICES_RESTART}: " \
      'checking status of hammer ping'
    end

    def apply_sleep_before_retry(spinner)
      spinner.update "Waiting #{PING_RETRY_INTERVAL} seconds before retry."
      sleep PING_RETRY_INTERVAL
    end
  end
end
