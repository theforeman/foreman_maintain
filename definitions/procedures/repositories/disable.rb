module Procedures::Repositories
  class Disable < ForemanMaintain::Procedure
    metadata do
      param :repos, 'List of repositories to disable'
      description 'Disable repositories'
    end
    def run
      with_spinner('Disabling repositories') do
        execute!("yum-config-manager --disable #{@repos}")
      end
    end
  end
end
