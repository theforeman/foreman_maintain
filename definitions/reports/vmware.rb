module Reports
  class Vmware < ForemanMaintain::Report
    metadata do
      description 'Check if vmware compute resource is used'
    end

    def run
      data_field('compute_resource_vmware_count') do
        sql_count("compute_resources WHERE type = 'Foreman::Model::Vmware'")
      end
    end
  end
end
