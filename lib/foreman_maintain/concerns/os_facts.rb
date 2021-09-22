module ForemanMaintain
  module Concerns
    module OsFacts
      OS_RELEASE_FILE = '/etc/os-release'.freeze

      def facts
        facts = {}
        tr_map = { '"' => '', "\n" => '' }
        rexp = Regexp.union(tr_map.keys)
        file = File.open(OS_RELEASE_FILE)
        file.readlines.each do |line|
          key, value = line.gsub(rexp, tr_map).split('=')
          facts[key] = value unless key.nil?
        end
        facts
      end

      def os_version_id
        facts.fetch('VERSION_ID')
      end

      def os_id
        facts.fetch('ID')
      end

      def os_id_like_list
        return facts.fetch('ID_LIKE').split(' ') if facts.key?('ID_LIKE')

        []
      end

      def el?
        ids = %w[rhel fedora]
        File.exist?('/etc/redhat-release') ||
          ids.include?(os_id) ||
          (ids & os_id_like_list).any?
      end

      def debian?
        File.exist?('/etc/debian_version') ||
          os_id == 'debian' ||
          os_id_like_list.include?('debian')
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
