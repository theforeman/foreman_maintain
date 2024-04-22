module Procedures::Packages
  class CheckForReboot < ForemanMaintain::Procedure
    metadata do
      description 'Check if system needs reboot'
    end

    def run
      status, output = package_manager.reboot_required?
      if status == 1
        set_info_warn(output)
      else
        set_status(:success, output)
      end
    end
  end
end
