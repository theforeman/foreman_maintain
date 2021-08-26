module ForemanMaintain::Utils
  module Facter
    include ForemanMaintain::Concerns::SystemHelpers

    FACTER_FILES = %w[/opt/puppetlabs/bin/facter /usr/bin/facter].freeze

    def self.package
      File.exist?('/opt/puppetlabs/bin/facter') ? 'puppet-agent' : 'facter'
    end

    def self.path
      FACTER_FILES.find { |path| File.exist?(path) }
    end
  end
end
