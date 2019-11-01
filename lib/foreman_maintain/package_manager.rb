require 'foreman_maintain/package_manager/base'
require 'foreman_maintain/package_manager/yum'
require 'foreman_maintain/package_manager/dnf'

module ForemanMaintain
  def self.package_manager
    @package_manager ||= case (%w[dnf yum apt].find { |manager| !`command -v #{manager}`.empty? })
                         when 'dnf'
                           ForemanMaintain::PackageManager::Dnf.new
                         when 'yum'
                           ForemanMaintain::PackageManager::Yum.new
                         else
                           raise 'No supported package manager was found'
                         end
  end
end
