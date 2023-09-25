module Procedures::Packages
  class CheckForReboot < ForemanMaintain::Procedure
    metadata do
      description 'Check if system needs reboot'
    end

    def run
      status, output = execute_with_status('dnf needs-restarting --reboothint')
      if status == 1
        set_status(:warning, output)
      else
        set_status(:success, output)
      end
    end
  end
end
