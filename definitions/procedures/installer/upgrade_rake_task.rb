module Procedures::Installer
  class UpgradeRakeTask < ForemanMaintain::Procedure
    metadata do
      description 'Execute upgrade:run rake task'
    end

    def run
      # only run this in the Satellite scenario, as in others
      # the installer runs this rake task for us already
      execute!('foreman-rake upgrade:run') if feature(:satellite)
    end
  end
end
