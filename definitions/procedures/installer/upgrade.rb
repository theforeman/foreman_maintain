module Procedures::Installer
  class Upgrade < ForemanMaintain::Procedure
    def run
      feature(:installer).upgrade(:interactive => true)
    end
  end
end
