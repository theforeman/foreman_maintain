module Procedures::Installer
  class UpgradeRakeTask < ForemanMaintain::Procedure
    metadata do
      description 'Execute upgrade:run rake task'
    end

    def run
      execute!('foreman-rake upgrade:run')
    end
  end
end
