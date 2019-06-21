module Procedures::Files
  class Remove < ForemanMaintain::Procedure
    metadata do
      description 'Remove the files'
      param :files, 'Files to remove', :array => true
      param :assumeyes, 'Do not ask for confirmation', :default => false
    end

    def run
      FileUtils.rm_r(@files, :force => @assumeyes, :secure => true)
    end
  end
end
