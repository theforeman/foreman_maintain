module Procedures::ForemanDocker
  class RemoveForemanDocker < ForemanMaintain::Procedure
    metadata do
      advanced_run false
      description 'Drop foreman_docker plugin'
      confine do
        find_package(foreman_plugin_name('foreman_docker'))
      end
    end

    def run
      execute!('foreman-rake foreman_docker:cleanup')
      packages_action(:remove, foreman_plugin_name('foreman_docker'), :assumeyes => true)
    end
  end
end
