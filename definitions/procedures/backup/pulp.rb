module Procedures::Backup
  class Pulp < ForemanMaintain::Procedure
    metadata do
      description 'Backup Pulp data'
      tags :backup
      for_feature :pulp2
      param :backup_dir, 'Directory where to backup to', :required => true
      param :tar_volume_size, 'Size of tar volume (indicates splitting)'
      param :ensure_unchanged, 'Ensure the data did not change during backup'
      param :skip, 'Skip Pulp content during backup'
      param :mount_dir, 'Snapshot mount directory'
    end

    def run
      skip if @skip
      with_spinner('Collecting Pulp data') do
        FileUtils.cd(pulp_dir) do
          if @ensure_unchanged
            ensure_dir_unchanged { pulp_backup }
          else
            pulp_backup
          end
        end
      end
    end

    private

    def pulp_backup
      feature(:tar).run(
        :archive => File.join(@backup_dir, 'pulp_data.tar'),
        :command => 'create',
        :exclude => ['var/lib/pulp/katello-export'],
        :listed_incremental => File.join(@backup_dir, '.pulp.snar'),
        :transform => 's,^,var/lib/pulp/,S',
        :volume_size => @tar_volume_size,
        :files => '*'
      )
    end

    def pulp_dir
      return feature(:pulp2).data_dir if @mount_dir.nil?
      mount_point = File.join(@mount_dir, 'pulp')
      dir = feature(:pulp2).find_marked_directory(mount_point)
      unless dir
        raise ForemanMaintain::Error::Fail,
              "Pulp base directory not found in the mount point (#{mount_point})"
      end
      dir
    end

    def ensure_dir_unchanged
      matching = false
      backup_file = File.join(@backup_dir, '.pulp.snar')
      alternate_backup = File.join(@backup_dir, '.pulp.snar.backup')
      until matching
        FileUtils.cp(backup_file, alternate_backup) if File.exist? backup_file
        checksum1 = compute_checksum
        yield
        checksum2 = compute_checksum
        matching = (checksum1 == checksum2)
        FileUtils.rm backup_file unless matching
        if File.exist? alternate_backup
          matching ? FileUtils.rm(alternate_backup) : FileUtils.mv(alternate_backup, backup_file)
        end
        logger.info("Data in #{pulp_dir} changed during backup. Retrying...") unless matching
      end
    end

    def compute_checksum
      execute!("find . -printf '%T@\n' | sha1sum")
    end
  end
end
