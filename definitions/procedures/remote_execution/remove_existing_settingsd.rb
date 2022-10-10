module Procedures::RemoteExecution
  class RemoveExistingSettingsd < ForemanMaintain::Procedure
    metadata do
      param :dirpath,
        'Directory path for settings.d folder',
        :required => true
      description 'Remove existing settings.d directory before installer run.' \
        "\n The next run of the installer will re-create the directory properly."
      advanced_run false
    end

    def run
      with_spinner("Removing existing #{@dirpath} directory") do |_spinner|
        if Dir.pwd.strip.eql?(@dirpath)
          fail! "Failed: You are trying to delete the current directory '#{@dirpath}' "\
                'which is not possible'
        else
          execute!("rm -rf #{@dirpath}")
        end
      end
    end
  end
end
