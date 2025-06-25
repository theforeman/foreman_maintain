module Procedures::Iop
  class Update < ForemanMaintain::Procedure
    metadata do
      description 'Update Advisor engine'

      confine do
        feature(:iop_advisor_engine)
      end
    end

    def run
      pull_image
    end

    def pull_image
      execute_with_status("podman pull #{feature(:iop_advisor_engine).container_image}")
    end
  end
end
