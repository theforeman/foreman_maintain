module ForemanMaintain
  module Cli
    module BackupCommon
      def self.included(klass)
        klass.extend ClassMethods
      end

      def backup_dir
        @backup_dir ||= preserve_directory? ? backup_root_dir : backup_subdir
      end

      def timestamp
        DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')
      end

      def backup_subdir
        name = feature(:instance).product_name.downcase.tr(' ', '-')
        File.join(backup_root_dir, "#{name}-backup-" + timestamp)
      end

      def perform_backup(strategy, options = {})
        backup_scenario = backup_scenario(options, strategy)
        rescue_scenario = rescue_scenario(options, strategy)
        puts "Starting backup: #{Time.now}"
        run_scenario(backup_scenario, rescue_scenario)
        puts "Done with backup: #{Time.now}"
        final_message
        exit runner.exit_code
      end

      module ClassMethods
        # rubocop:disable  Metrics/MethodLength
        def common_backup_options
          # TODO: BACKUP_DIR in f-m config - should be default?
          parameter 'BACKUP_DIR', 'Path to backup dir',
                    :completion => { :type => :directory },
                    :attribute_name => :backup_root_dir do |dir|
            File.expand_path(dir)
          end
          option ['-s', '--skip-pulp-content'], :flag, 'Do not backup Pulp content'
          option ['-p', '--preserve-directory'], :flag, 'Do not create a time-stamped subdirectory'
          option ['-t', '--split-pulp-tar'], 'SPLIT_SIZE',
                 'Split pulp data into files of a specified size, i.e. (100M, 50G). ' \
                 "See '--tape-length' in 'info tar' for all sizes" do |size|
            self.class.valid_tape_size(size)
          end
          option ['-i', '--incremental'], 'PREVIOUS_BACKUP_DIR',
                 'Backup changes since previous backup',
                 :completion => { :type => :directory } do |dir|
            unless File.directory?(dir)
              raise ArgumentError, "Previous backup directory does not exist: #{dir}"
            end

            dir
          end
          proxy_name = ForemanMaintain.detector.feature(:capsule) ? 'Capsule' : 'Foreman Proxy'
          option '--features', 'FEATURES',
                 "#{proxy_name} features to include in the backup. " \
                     'Valid features are tftp, dns, dhcp, openscap, and all.', :multivalued => true
        end
        # rubocop:enable  Metrics/MethodLength

        def valid_tape_size(size)
          begin
            ForemanMaintain.detector.feature(:tar).validate_volume_size(size)
          rescue ForemanMaintain::Error::Validation => e
            raise ArgumentError, e.message
          end
          size
        end
      end

      private

      def rescue_scenario(options, strategy)
        Scenarios::BackupRescueCleanup.new({
          :backup_dir => backup_dir,
          :strategy => strategy,
          :preserve_dir => preserve_directory?
        }.merge(options))
      end

      def backup_scenario(options, strategy)
        Scenarios::Backup.new({
          :backup_dir => backup_dir,
          :strategy => strategy,
          :preserve_dir => preserve_directory?,
          :proxy_features => features,
          :tar_volume_size => split_pulp_tar,
          :skip_pulp_content => skip_pulp_content?,
          :incremental_dir => incremental
        }.merge(options))
      end

      def final_message
        if runner.quit?
          if preserve_directory?
            puts "Backup didn't finish. Incomplete backup is preserved in: #{backup_dir}"
          else
            puts "Backup didn't finish. Incomplete backup was removed."
          end
        else
          puts "**** BACKUP Complete, contents can be found in: #{backup_dir} ****"
        end
      end
    end

    class OnlineBackupCommand < Base
      include BackupCommon
      interactive_option
      common_backup_options

      def execute
        perform_backup(:online)
      end
    end

    class OfflineBackupCommand < Base
      include BackupCommon
      interactive_option
      common_backup_options
      option '--include-db-dumps', :flag, 'Also dump full database schema before offline backup'

      def execute
        perform_backup(:offline,
                       :include_db_dumps => include_db_dumps?)
      end
    end

    class SnapshotBackupCommand < Base
      include BackupCommon
      interactive_option
      common_backup_options
      option '--include-db-dumps', :flag, 'Also dump full database schema before snapshot backup'
      option ['-d', '--snapshot-mount-dir'], 'SNAPSHOT_MOUNT_DIR',
             "Override default directory ('/var/snap/') where the snapshots will be mounted",
             :default => '/var/snap/' do |dir|
        unless File.directory?(dir)
          raise ArgumentError, "Snapshot mount directory does not exist: #{dir}"
        end
        dir
      end
      option ['-b', '--snapshot-block-size'], 'SNAPSHOT_BLOCK_SIZE',
             'Override default block size (2G)', :default => '2G'

      def execute
        perform_backup(:snapshot,
                       :snapshot_mount_dir => snapshot_mount_dir,
                       :snapshot_block_size => snapshot_block_size,
                       :include_db_dumps => include_db_dumps?)
      end
    end

    # rubocop:disable Metrics/LineLength
    class BackupCommand < Base
      subcommand 'online', 'Keep services online during backup', OnlineBackupCommand
      subcommand 'offline', 'Shut down services to preserve consistent backup', OfflineBackupCommand
      subcommand 'snapshot', 'Use snapshots of the databases to create backup', SnapshotBackupCommand
    end
    # rubocop:enable Metrics/LineLength
  end
end
