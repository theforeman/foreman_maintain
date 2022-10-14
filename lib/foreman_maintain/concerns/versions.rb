module ForemanMaintain
  module Concerns
    module Versions
      def less_than_version?(version)
        Gem::Version.new(current_version) < Gem::Version.new(version)
      end

      def at_least_version?(version)
        Gem::Version.new(current_version) >= Gem::Version.new(version)
      end

      def current_minor_version
        current_version.to_s[/^\d+\.\d+/]
      end
    end
  end
end
