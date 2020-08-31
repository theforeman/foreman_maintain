module Procedures::Installer
  class Upgrade < ForemanMaintain::Procedure
    metadata do
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      feature(:installer).upgrade(:interactive => !assumeyes_val)
    end
  end
end
