require 'procedures/service/base'

module Procedures::Service
  class Restart < Base
    metadata do
      description 'Restart applicable services'
      Base.common_params(self)
      param :wait_for_hammer_ping,
            'Wait for hammer ping to return successfully before terminating'
      preparation_steps { Procedures::HammerSetup.new if feature(:katello) }
    end

    RETRIES_FOR_SERVICES_RESTART = 5
    PING_RETRY_INTERVAL = 30

    def run
      run_service_action('stop', common_options)
      run_service_action('start', common_options)
      hammer_ping_retry if @wait_for_hammer_ping
    end

    def hammer_ping_retry
      with_spinner('Checking hammer ping') do |spinner|
        RETRIES_FOR_SERVICES_RESTART.times do |retry_count|
          spinner.update retry_message(retry_count)
          result = feature(:hammer).hammer_ping_cmd
          if result[:success]
            spinner.update 'Hammer ping returned successfully!'
            break
          elsif retry_count < (RETRIES_FOR_SERVICES_RESTART - 1)
            apply_sleep_before_retry(spinner, result)
          else
            raise 'Hammer ping failed!'
          end
        end
      end
    end

    def retry_message(retry_count)
      "Try #{retry_count + 1}/#{RETRIES_FOR_SERVICES_RESTART}: " \
      'checking status of hammer ping'
    end

    def apply_sleep_before_retry(spinner, result)
      puts "\n#{result[:message]}"
      spinner.update "Waiting #{PING_RETRY_INTERVAL} seconds before retry."
      sleep PING_RETRY_INTERVAL
    end
  end
end
