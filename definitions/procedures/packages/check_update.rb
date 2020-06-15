module Procedures::Packages
  class CheckUpdate < ForemanMaintain::Procedure
    metadata do
      description 'Check for available package updates'
    end

    def run
      puts package_manager.check_update
    end
  end
end
