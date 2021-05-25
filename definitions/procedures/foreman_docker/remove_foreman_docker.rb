module Procedures::ForemanDocker
  class RemoveForemanDocker < ForemanMaintain::Procedure
    metadata do
      advanced_run false
      description 'Drop foreman_docker plugin'
    end

    def docker_package
      scl_or_nonscl_package('rubygem-foreman_docker')
    end

    def run
      return unless execute?("rpm -q #{docker_package}")

      execute!('foreman-rake foreman_docker:cleanup')
      packages_action(:remove, [docker_package], :assumeyes => true)
    end
  end
end
