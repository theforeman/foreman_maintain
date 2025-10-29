module Checks::Katello
  class CheckCleanBackendObjects < ForemanMaintain::Check
    metadata do
      description 'Check whether subscription consumers of backend service is in sync'
      tags :pre_upgrade

      confine do
        feature(:katello)
      end
    end

    def warn_hosts(missing_sub_info)
      unless missing_sub_info.empty?
        puts "Hosts missing subscription information and would be un-registered:"
        puts missing_sub_info.map { |e| "  * #{e[1]}(#{e[0]})" }.join("\n")
      end
    end

    def clean_backend_objects_dry_run
      found_orphans = nil
      missing_sub_info = []
      list_cmd = "export RUBYOPT='-W0'; foreman-rake katello:clean_backend_objects"
      execute(list_cmd).each_line do |line|
        case line
        when /^(?<orphans>\d+) orphaned consumer id\(s\) found in candlepin\.$/
          found_orphans = Regexp.last_match(:orphans).to_i
          puts "Found #{found_orphans} orphans" if found_orphans > 0
        when /^Candlepin orphaned consumers: (?<orphaned_consumers>.*)$/
          orphaned_consumers = Regexp.last_match(:orphaned_consumers)
          puts "Found consumers: #{orphaned_consumers}" if orphaned_consumers != '[]'
        when /^Host (?<id>\S*) (?<host>\S*) (?<sub>\S*)? is partially missing subscription/
          missing_sub_info << [Regexp.last_match(:id), Regexp.last_match(:host)]
        end
      end
      warn_hosts(missing_sub_info)
      return found_orphans + missing_sub_info.length
    end

    def run
      assert clean_backend_objects_dry_run.zero?,
        "'katello:clean_backend_objects' would remove the above Candlepin consumers and hosts!\n" \
        "Please verify, if this is valid. One solution can be to re-subscribe affected host.\n"
    end
  end
end
