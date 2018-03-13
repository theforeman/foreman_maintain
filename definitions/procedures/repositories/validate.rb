module Procedures::Repositories
  class Validate < ForemanMaintain::Procedure
    metadata do
      description 'Validate repositories'

      confine do
        feature(:downstream) || feature(:upstream)
      end

      param :version,
            'Version for which repositories needs to be validated',
            :required => true
    end

    def run
      with_spinner("Validating repositories for #{@version}") do
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
