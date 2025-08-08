# frozen_string_literal: true

module Reports
  class DisconnectedEnvironment < ForemanMaintain::Report
    metadata do
      description 'Checks if the instance is in a disconnected environment'
    end

    def run
      data_field('disconnected_environment') do
        subscription_connection_setting = sql_setting('subscription_connection_enabled')

        # If setting doesn't exist, assume connected (not disconnected)
        if subscription_connection_setting.nil?
          false
        else
          # disconnected when subscription_connection_enabled is false
          YAML.safe_load(subscription_connection_setting) == false
        end
      end
    end
  end
end
