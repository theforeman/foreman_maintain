module Procedures::Installer
  class Run < ForemanMaintain::Procedure
    metadata do
      param :arguments, 'Arguments passed to installer'
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      # If assumeyes selected we execute installer in non-interactive mode
      feature(:installer).run(@arguments, :interactive => !assumeyes_val)
    end

    def description
      "Running #{feature(:installer).installer_command} #{@arguments}"
    end
  end
end
