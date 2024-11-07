module Procedures::Repositories
  class IndexKatelloRepositoriesContainerMetatdata < ForemanMaintain::Procedure
    metadata do
      description 'Import container manifest metadata'
      confine do
        feature(:katello)
      end
    end

    def run
      with_spinner('Adding image metadata to Katello.') do
        execute!('foreman-rake katello:import_container_manifest_labels')
      end
    end
  end
end
