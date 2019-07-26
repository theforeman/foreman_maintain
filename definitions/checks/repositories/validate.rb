module Checks::Repositories
  class Validate < ForemanMaintain::Check
    metadata do
      description 'Validate availability of repositories'
      preparation_steps do
        Procedures::Packages::Install.new(:packages => [ForemanMaintain::Utils::Facter.package])
      end

      confine do
        feature(:instance).downstream
      end

      param :version,
            'Version for which repositories needs to be validated',
            :required => true

      manual_detection
    end

    def run
      if feature(:instance).downstream.subscribed_using_activation_key?
        skip 'Your system is subscribed using custom activation key'
      else
        with_spinner("Validating availability of repositories for #{@version}") do |spinner|
          find_absent_repos(spinner)
        end
      end
    end

    private

    def find_absent_repos(spinner)
      absent_repos = feature(:instance).downstream.absent_repos(@version)
      unless absent_repos.empty?
        spinner.update('Some repositories missing, calling `subscription-manager refresh`')
        feature(:instance).downstream.rhsm_refresh
        absent_repos = feature(:instance).downstream.absent_repos(@version)
      end
      unless absent_repos.empty?
        fail!(
          "Following repositories are not available on your system: #{absent_repos.join(', ')}"
        )
      end
    end
  end
end
