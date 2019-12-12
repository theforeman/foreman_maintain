module Procedures::Hammer
  class ReloadCache < ForemanMaintain::Procedure
    metadata do
      advanced_run false
      description 'Reload Hammer cache'
      for_feature :hammer
    end

    def run
      with_spinner('Reloading Hammer cache') do |_spinner|
        feature(:hammer).run('--reload-cache')
      end
    end
  end
end
