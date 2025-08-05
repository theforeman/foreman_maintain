# frozen_string_literal: true

module Reports
  class Webhooks < ForemanMaintain::Report
    metadata do
      description 'Report about webhook usage'
    end

    def run
      data_field('webhooks_enabled_count') { sql_count('webhooks WHERE enabled = true') }
      data_field('webhooks_subscribed_events') { webhooks_subscribed_events }
      data_field('shell_hooks_count') { sql_count('webhooks WHERE proxy_authorization = true') }
    end

    private

    def webhooks_subscribed_events
      # Extract all events from webhooks table and join into comma-separated string
      events_data = query('SELECT events FROM webhooks')
      
      all_events = []
      events_data.each do |row|
        events_value = row['events']
        next if events_value.nil? || events_value.empty?
        
        # Parse the array-like string - handle both JSON array format and simple arrays
        # Remove outer brackets/braces, quotes, and split by comma
        cleaned_value = events_value.gsub(/^[\[\{]|[\]\}]$/, '').gsub(/["']/, '')
        parsed_events = cleaned_value.split(',').map(&:strip)
        all_events.concat(parsed_events)
      end
      
      # Remove duplicates and join with commas
      all_events.uniq.reject(&:empty?).join(',')
    end
  end
end
