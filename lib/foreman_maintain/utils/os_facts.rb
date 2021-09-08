module ForemanMaintain::Utils
  module OsFacts
    include ForemanMaintain::Concerns::SystemHelpers
    OS_RELEASE = '/etc/os-release'.freeze

    def self.grep_cmd(str)
      execute!("grep -w #{str} #{OS_RELEASE}|cut -d'=' -f 2").tr('"', '')
    end

    def self.version_id
      grep_cmd('VERSION_ID')
    end

    def self.id
      grep_cmd('ID')
    end

    def self.id_like
      grep_cmd('ID_LIKE')
    end
  end
end
