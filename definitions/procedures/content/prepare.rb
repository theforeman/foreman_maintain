module Procedures::Content
  class Prepare < ForemanMaintain::Procedure
    metadata do
      description 'Prepare content for Pulp 3'
      for_feature :pulpcore
      param :quiet, 'Keep the output on a single line', :flag => true, :default => false
      do_not_whitelist
    end

    def run
      sleep(20) # in satellite 6.9 the services are still coming up
      # use interactive to get realtime output
      env_vars = @quiet ? '' : 'preserve_output=true '
      execute!("#{env_vars}foreman-rake katello:pulp3_migration", :interactive => true)
    end
  end
end
