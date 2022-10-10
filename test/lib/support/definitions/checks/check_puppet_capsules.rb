module Checks
  class CheckPuppetCapsules < ForemanMaintain::Check
    metadata do
      label :puppet_capsules
      for_feature :foreman_database
      description 'Check for Puppet capsules from the database'
      manual_detection
    end

    def run
    end
  end
end
