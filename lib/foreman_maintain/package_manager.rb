require 'foreman_maintain/package_manager/base'
require 'foreman_maintain/package_manager/yum'
require 'foreman_maintain/package_manager/dnf'
require 'foreman_maintain/package_manager/apt'

module ForemanMaintain
  def self.find_pkg_manager
    %w[dnf yum apt].find do |manager|
      system('which', manager.to_s, [:out, :err] => File::NULL)
    end
  end

  def self.package_manager
    @package_manager ||= case find_pkg_manager
                         when 'dnf'
                           ForemanMaintain::PackageManager::Dnf.new
                         when 'yum'
                           ForemanMaintain::PackageManager::Yum.new
                         when 'apt'
                           ForemanMaintain::PackageManager::Apt.new
                         else
                           raise 'No supported package manager was found'
                         end
  end
end
