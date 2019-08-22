module Procedures::Installer
  class Run < ForemanMaintain::Procedure
    metadata do
      param :arguments, 'Arguments passed to installer'
    end

    def run
      feature(:installer).run(@arguments, :interactive => true)
    end

    def description
      "Running #{feature(:installer).installer_command} #{@arguments}"
    end
  end
end
