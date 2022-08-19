require 'foreman_maintain/foreman_and_katello_version_map'

module ForemanMaintain
  module Concerns
    module ForemanAndKatelloVersionMap
      def foreman_version_by_katello(version)
        ForemanMaintain::FOREMAN_AND_KATELLO_VERSION_MAP.key(version)
      end

      def katello_version_by_foreman(version)
        ForemanMaintain::FOREMAN_AND_KATELLO_VERSION_MAP.fetch(version)
      end
    end
  end
end
