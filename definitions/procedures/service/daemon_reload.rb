module Procedures::Service
  class DaemonReload < ForemanMaintain::Procedure
    include ForemanMaintain::Concerns::SystemHelpers
    metadata do
      description 'Run daemon reload'

      confine do
        systemd_installed?
      end
    end

    def run
      unless feature(:instance).foreman_proxy_with_content?
        execute!('systemctl daemon-reload')
      end
    end
  end
end
