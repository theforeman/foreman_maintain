module Procedures::Installer
  class Upgrade < ForemanMaintain::Procedure
    metadata do
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      # If assumeyes selected we execute installer in non-interactive mode
      feature(:installer).run(@arguments, :interactive => !assumeyes_val)
    end
  end
end
