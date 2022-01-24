module Checks::MaintenanceMode
  class CheckConsistency < ForemanMaintain::Check
    metadata do
      label :check_maintenance_mode_consistency
      description 'Check of maintenance-mode consistency'
      advanced_run false
    end

    def run
      procedure_arr = []
      message_to_show = ''
      with_spinner('Running status of maintenance-mode') do |_spinner|
        message_to_show, procedure_arr = verify_with_features
      end
      puts message_to_show
      assert(
        procedure_arr.empty?,
        'You can follow remediation procedure(s) to fix maintenance-mode state',
        :next_steps => procedure_arr
      )
    end

    private

    def verify_with_features
      procedure_arr = []
      feature_status_msgs = []
      is_mode_on = feature(:instance).firewall.maintenance_mode_status?
      [feature(:instance).firewall.label, :sync_plans, :cron].each do |feature_name|
        msg, procedures_to_run = send("check_for_#{feature_name}", is_mode_on)
        feature_status_msgs << msg
        procedure_arr.concat(procedures_to_run)
      end
      [construct_message(is_mode_on, feature_status_msgs), procedure_arr]
    end

    def construct_message(is_mode_on, feature_status_msgs)
      info_string = "\nStatus of maintenance-mode: #{is_mode_on ? 'On' : 'Off'}"
      unless feature_status_msgs.empty?
        info_string += "\n- "
      end
      info_string += feature_status_msgs.join("\n- ")
      info_string
    end

    def check_for_cron(is_mode_on)
      unless ForemanMaintain.config.manage_crond && feature(:cron)
        return ['cron jobs: not managed', []]
      end

      feature(:cron).status_for_maintenance_mode(is_mode_on)
    end

    def check_for_iptables(_is_mode_on)
      feature(:iptables).status_for_maintenance_mode
    end

    def check_for_nftables(_is_mode_on)
      feature(:nftables).status_for_maintenance_mode
    end

    def check_for_sync_plans(is_mode_on)
      feature(:sync_plans).status_for_maintenance_mode(is_mode_on)
    end
  end
end
