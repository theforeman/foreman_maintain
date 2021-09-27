module ForemanMaintain
  module Concerns
    module OsFacts
      OS_RELEASE_FILE = '/etc/os-release'.freeze

      def facts
        unless defined?(@facts)
          @facts = {}
          File.open(OS_RELEASE_FILE) do |file|
            file.readlines.each do |line|
              line.strip! # drop any whitespace, including newlines from start and end of the line
              next if line.start_with?('#') # ignore comments
              # split at most into 2 items, if the value ever contains an =
              key, value = line.split('=', 2)
              @facts[key] = value.delete('"') unless key.nil?
            end
          end
        end
        @facts
      end

      def os_version_id
        facts.fetch('VERSION_ID')
      end

      def os_id
        facts.fetch('ID')
      end

      def os_id_like_list
        facts.fetch('ID_LIKE', '').split
      end

      def el?
        File.exist?('/etc/redhat-release')
      end

      def debian?
        File.exist?('/etc/debian_version')
      end

      def el7?
        el_major_version == 7
      end

      def el8?
        el_major_version == 8
      end

      def el_major_version
        return os_version_id.to_i if el?
      end
    end
  end
end
