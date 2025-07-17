module Procedures::Iop
  class Update < ForemanMaintain::Procedure
    metadata do
      description 'Update IoP containers'

      confine do
        feature(:iop)
      end
    end

    def run
      pull_image
    end

    def pull_image
      execute_with_status("podman pull #{feature(:iop).container_image}")
    end
  end
end
