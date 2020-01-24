module ForemanMaintain::Utils
  module Facter
    include ForemanMaintain::Concerns::SystemHelpers

    FACTER_FILES = %w[/usr/bin/facter /opt/puppetlabs/bin/facter].freeze

    def self.package
      puppet_version = version(execute!('/opt/puppetlabs/bin/puppet --version'))

      puppet_version.major >= 4 ? 'puppet-agent' : 'facter'
    end

    def self.path
      FACTER_FILES.find { |path| File.exist?(path) }
    end

    def self.os_major_release
      execute!("#{path} operatingsystemmajrelease")
    end
  end
end
