module Procedures::Timer
  class Start < ForemanMaintain::Procedure
    metadata do
      description 'Start systemd timers'

      for_feature :timer
      tags :post_migrations
    end

    def run
      with_spinner('Starting systemd timers') do |spinner|
        feature(:timer).handle_timers(spinner, 'start')
      end
    end
  end
end
