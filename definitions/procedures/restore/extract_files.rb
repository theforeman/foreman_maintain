module Procedures::Restore
  class ExtractFiles < ForemanMaintain::Procedure
    metadata do
      description 'Extract any existing tar files in backup'

      param :backup_dir,
        'Path to backup directory',
        :required => true
    end

    def run
      backup = ForemanMaintain::Utils::Backup.new(@backup_dir)
      with_spinner('Extracting Files') do |spinner|
        if backup.file_map[:pulp_data][:present]
          spinner.update('Extracting pulp data')
          extract_pulp_data(backup)
        end
      end
    end

    def base_tar
      {
        :overwrite => true,
        :absolute_names => true,
        :listed_incremental => '/dev/null',
        :command => 'extract',
        :directory => '/',
      }
    end

    def extract_pulp_data(backup)
      pulp_data_tar = if backup.pulp_tar_split?
                        base_tar.merge(
                          :multi_volume => true,
                          :split_data => true,
                          :archive => backup.file_map[:pulp_data][:path]
                        )
                      else
                        base_tar.merge(
                          :archive => backup.file_map[:pulp_data][:path]
                        )
                      end

      feature(:tar).run(pulp_data_tar)
    end

    def any_database
      %i[
        foreman_database
        candlepin_database
        pulpcore_database
        container_gateway_database
      ].any? { |db| feature(db) }
    end
  end
end
