require 'foreman_maintain/package_manager/base'
require 'foreman_maintain/package_manager/yum'
require 'foreman_maintain/package_manager/dnf'
require 'foreman_maintain/package_manager/apt'

module ForemanMaintain
  def self.package_manager
    @package_manager ||= if el7?
                           ForemanMaintain::PackageManager::Yum.new
                         elsif el?
                           ForemanMaintain::PackageManager::Dnf.new
                         elsif debian?
                           ForemanMaintain::PackageManager::Apt.new
                         else
                           raise 'No supported package manager was found'
                         end
  end
end
