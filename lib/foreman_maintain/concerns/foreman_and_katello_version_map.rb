module ForemanMaintain
  module Concerns
    module ForemanAndKatelloVersionMap
      FOREMAN_AND_KATELLO_VERSION_MAP = {
        'nightly' => 'nightly'
      }.freeze

      def foreman_version_by_katello(version)
        FOREMAN_AND_KATELLO_VERSION_MAP.key(version)
      end

      def katello_version_by_foreman(version)
        FOREMAN_AND_KATELLO_VERSION_MAP.fetch(version)
      end
    end
  end
end
