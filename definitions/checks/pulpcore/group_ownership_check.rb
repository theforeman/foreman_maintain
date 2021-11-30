module Checks
  module Pulpcore
    class GroupOwnershipCheck < ForemanMaintain::Check
      metadata do
        description 'Check the group owner of /var/lib/pulp directory'
        label :group_ownership_check_of_pulp_content
        manual_detection
      end

      def run
        group_id = File.stat('/var/lib/pulp/').gid
        if Etc.getgrgid(group_id).name != 'pulp'
          fail! "Please run 'foreman-maintain prep-6.10-upgrade' prior to upgrading."
        end
      end
    end
  end
end
