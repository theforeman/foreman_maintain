module Procedures::Iop
  class Update < ForemanMaintain::Procedure
    metadata do
      description 'Update IoP containers'

      confine do
        feature(:iop)
      end
    end

    def run
      pull_images
    end

    def pull_images
      feature(:iop).container_images.each do |container_image|
        execute_with_status("podman pull #{container_image}")
      end
    end
  end
end
