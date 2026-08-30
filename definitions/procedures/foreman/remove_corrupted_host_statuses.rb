module Procedures::Foreman
  class RemoveCorruptedHostStatuses < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_database
      description 'Remove corrupted host statuses'
    end

    def run
      corrupted = collect_host_status_with_type_nil
      if corrupted.empty?
        skip("No corrupted host status. Everything fine. Exit.")
      end

      print("Detected corrupted host statuses:\n")
      corrupted.each do |s|
        print("Host #{s['host_name']} has corrupted host_status with id #{s['host_status_id']}\n")
      end

      answer = ask_decision("Do you want to remove the statuses", actions_msg: 'y(yes), q(quit)')
      abort! unless answer == :yes

      with_spinner('Removing corrupted host statuses') do
        delete_host_status_with_type_nil
      end
    end

    private

    def collect_host_status_with_type_nil
      feature(:foreman_database).query(
        "SELECT hosts.name AS host_name, host_status.id AS host_status_id
         FROM hosts, host_status
         WHERE host_status.type IS NULL AND hosts.id = host_status.host_id"
      )
    end

    def delete_host_status_with_type_nil
      feature(:foreman_database).psql(
        "DELETE FROM host_status WHERE type IS NULL"
      )
    end
  end
end
