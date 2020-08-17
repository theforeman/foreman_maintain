module Procedures::Installer
  class Upgrade < ForemanMaintain::Procedure
    metadata do
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      if package_version('foreman-installer').version >= '2.1'
        feature(:installer).run(@arguments, :interactive => !assumeyes_val)
      else
        feature(:installer).upgrade(:interactive => !assumeyes_val)
      end
    end
  end
end
