module Procedures::Iop
  class Update < ForemanMaintain::Procedure
    metadata do
      description 'Update IoP containers'

      confine do
        feature(:iop) && (feature(:satellite)&.connected? || !feature(:satellite))
      end

      param :version,
        'Version of the containers to pull',
        :required => true
    end

    def run
      pull_images
    end

    def pull_images
      feature(:iop).container_images(@version).each do |container_image|
        execute!("podman pull #{container_image}")
      end
    end
  end
end
