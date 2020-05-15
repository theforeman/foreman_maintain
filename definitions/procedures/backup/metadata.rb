module Procedures::Backup
  class Metadata < ForemanMaintain::Procedure
    metadata do
      description 'Generate metadata'
      tags :backup
      preparation_steps { Checks::Foreman::DBUp.new if feature(:foreman_server) }
      param :backup_dir, 'Directory where to backup to', :required => true
      param :incremental_dir, 'Changes since specified backup only'
      param :online_backup, 'Select for online backup', :flag => true, :default => false
    end

    def run
      with_spinner('Collecting metadata') do |spinner|
        metadata = {}
        metadata['os_version'] = release_info(spinner)
        metadata['plugin_list'] = plugin_list(spinner) || []
        metadata['proxy_features'] = proxy_feature_list(spinner) || []
        metadata['rpms'] = rpms(spinner)
        metadata['incremental'] = @incremental_dir || false
        metadata['online'] = @online_backup
        save_metadata(metadata, spinner)
      end
    end

    private

    def save_metadata(metadata, spinner)
      spinner.update('Saving metadata to metadata.yml')
      File.open(File.join(@backup_dir, 'metadata.yml'), 'w') do |metadata_file|
        metadata_file.puts metadata.to_yaml
      end
    end

    def release_info(spinner)
      spinner.update('Collecting system release info')
      execute!('cat /etc/redhat-release').chomp
    end

    def rpms(spinner)
      spinner.update('Collecting installed RPMs')
      execute!('rpm -qa').split("\n")
    end

    def plugin_list(spinner)
      if feature(:foreman_server)
        spinner.update('Collecting list of plugins')
        feature(:foreman_server).plugins
      end
    end

    def proxy_feature_list(spinner)
      if feature(:foreman_proxy)
        spinner.update('Collecting list of proxy features')
        feature(:foreman_proxy).features
      end
    end
  end
end
