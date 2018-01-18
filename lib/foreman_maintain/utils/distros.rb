require 'foreman_maintain/utils/distros/redhat'
require 'foreman_maintain/utils/distros/debian'
require 'foreman_maintain/utils/distros/fedora'

module ForemanMaintain
  module Utils
    class Distros
      include ForemanMaintain::Concerns::SystemExecutable

      attr_accessor :upgrade_version

      def arch
        'x86_64'
      end

      def domain
        'yum.theforeman.org'
      end

      def setup_repositories
        execute!(%(yum upgrade #{upstream_repo} -y))
        execute!(%(yum clean all))
        execute!(%(yum install foreman-release-scl -y))
      end

      def upstream_repo
        "https://#{domain}/releases/#{upgrade_version}/#{release_name}/#{arch}/foreman-release.rpm"
      end
    end
  end
end
