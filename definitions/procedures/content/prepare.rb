module Procedures::Content
  class Prepare < ForemanMaintain::Procedure
    metadata do
      description 'Prepare content for Pulp 3'
      for_feature :pulpcore
      param :quiet, 'Keep the output on a single line', :flag => true, :default => false
    end

    def run
      # use interactive to get realtime output
      env_vars = @quiet ? '' : 'preserve_output=true '
      puts execute!("#{env_vars}foreman-rake katello:pulp3_migration", :interactive => true)
    end
  end
end
