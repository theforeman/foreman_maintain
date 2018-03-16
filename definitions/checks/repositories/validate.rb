module Checks::Repositories
  class Validate < ForemanMaintain::Check
    metadata do
      description 'Validate availability of repositories'

      confine do
        feature(:downstream)
      end

      param :version,
            'Version for which repositories needs to be validated',
            :required => true

      manual_detection
    end

    def run
      with_spinner("Validating availability of repositories for #{@version}") do
        absent_repos = feature(:downstream).absent_repos(@version)
        unless absent_repos.empty?
          fail!(
            "Following repositories are not available on your system: #{absent_repos.join(', ')}"
          )
        end
      end
    end
  end
end
