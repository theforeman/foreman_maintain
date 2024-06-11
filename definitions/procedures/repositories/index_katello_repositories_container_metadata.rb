module Procedures::Repositories
  class IndexKatelloRepositoriesContainerMetatdata < ForemanMaintain::Procedure
    metadata do
      description 'Import container manifest metadata'
      confine do
        feature(:katello)
      end
    end

    def run
      with_spinner(('Adding image metadata. You can continue using the ' \
                    'system normally while the task runs in the background.')) do
        execute!('foreman-rake katello:import_container_manifest_labels')
      end
    end
  end
end
