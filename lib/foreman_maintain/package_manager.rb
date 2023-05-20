require 'foreman_maintain/package_manager/base'
require 'foreman_maintain/package_manager/dnf'
require 'foreman_maintain/package_manager/apt'

module ForemanMaintain
  def self.package_manager
    if el?
      ForemanMaintain::PackageManager::Dnf.new
    elsif debian_or_ubuntu?
      ForemanMaintain::PackageManager::Apt.new
    else
      raise 'No supported package manager was found'
    end
  end
end
