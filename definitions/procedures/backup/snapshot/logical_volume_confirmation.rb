module Procedures::Backup
  module Snapshot
    class LogicalVolumeConfirmation < ForemanMaintain::Procedure
      metadata do
        description 'Check if backup is on different logical volume then the source'
        tags :backup
        param :backup_dir, 'Directory where to backup to', :required => true
        param :skip_pulp, 'Skip Pulp content during backup'
      end

      def run
        backup_lv = get_lv_info(@backup_dir)
        shared_lv = dbs.inject([]) do |list, (db_label, db_name)|
          db_lv = get_lv_info(feature(db_label).data_dir)
          list << db_name if db_lv == backup_lv
          list
        end

        pulp_data_lv = get_lv_info(current_pulp_feature.pulp_data_dir)
        shared_lv << 'Pulp' if pulp_data_lv == backup_lv && !@skip_pulp

        confirm(shared_lv) if shared_lv.any?
      end

      def current_pulp_feature
        feature(:pulp2) || feature(:pulpcore_database)
      end

      def dbs
        dbs = {}
        dbs[:mongo] = 'Mongo' if db_local?(:mongo)
        dbs[:candlepin_database] = 'Candlepin' if db_local?(:candlepin_database)
        dbs[:foreman_database] = 'Foreman' if db_local?(:foreman_database)
        dbs[:pulpcore_database] = 'Pulpcore' if db_local?(:pulpcore_database)
        dbs
      end

      private

      def db_local?(db)
        feature(:instance).database_local?(db)
      end

      def confirm(shared_lv)
        answer = ask_decision('*** WARNING: The chosen backup location is mounted on the same' \
          " logical volume as the location of #{shared_lv.join(', ')}.\n" \
          '*** It is highly suggested to backup to a different logical volume than' \
          " the #{shared_lv.join(', ')} database.\n" \
          '*** If you would like to continue, the snapshot size will be required to be at least' \
          " the size of the actual #{shared_lv.join(', ')} database.\n" \
          "*** You can skip this confirmation with the '-y' flag.\n\n" \
          'Do you want to proceed?', actions_msg: 'y(yes), q(quit)')
        abort! unless answer == :yes
      end
    end
  end
end
