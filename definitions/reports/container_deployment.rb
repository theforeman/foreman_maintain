module Reports
  class ContainerDeploymentCheck < ForemanMaintain::Report
    metadata do
      description 'Checks whether the deployment is package or container based'
    end

    def run
      data_field('container_deployment') do
        File.exist?('/etc/containers/systemd/foreman.container')
      end
    end
  end
end
