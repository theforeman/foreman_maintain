module Procedures::ForemanDocker
  class RemoveForemanDocker < ForemanMaintain::Procedure
    metadata do
      advanced_run false
      description 'Drop foreman_docker plugin'
    end

    def docker_package
      find_package(foreman_plugin_name('foreman_docker'))
    end

    def run
      return unless execute?("rpm -q #{docker_package}")

      execute!('foreman-rake foreman_docker:cleanup')
      packages_action(:remove, [docker_package], :assumeyes => true)
    end
  end
end
