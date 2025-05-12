module Procedures::Iop
  class ImagePrune < ForemanMaintain::Procedure
    metadata do
      description 'Prune unused IoP container images'

      confine do
        feature(:iop)
      end
    end

    def run
      prune_images
    end

    def prune_images
      execute!("podman image prune --force")
    end
  end
end
