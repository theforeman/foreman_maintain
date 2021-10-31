module Procedures::Puppet
  class RemovePuppetData < ForemanMaintain::Procedure
    metadata do
      description 'Remove Puppet data'
    end

    def run
      execute!('foreman-rake purge:puppet')
      execute!('rm -r ' + files_to_purge.join(' '))
    end

    private

    def files_to_purge
      %w[
        /etc/puppetlabs
        /opt/puppetlabs/server/data
      ]
    end
  end
end
