module Procedures::Timer
  class Stop < ForemanMaintain::Procedure
    metadata do
      description 'Stop systemd timers'

      for_feature :timer
      confine do
        feature(:timer)&.existing_timers&.any?
      end

      tags :pre_migrations
    end

    def run
      with_spinner('Stopping systemd timers') do |spinner|
        feature(:timer).handle_timers(spinner, 'stop')
      end
    end
  end
end
