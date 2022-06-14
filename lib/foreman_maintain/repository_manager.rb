require 'foreman_maintain/repository_manager/el'
require 'foreman_maintain/repository_manager/apt'
include ForemanMaintain::Concerns::OsFacts
module ForemanMaintain
  def self.repository_manager
    @repository_manager ||= if el?
                              ForemanMaintain::RepositoryManager::El.new
                            elsif debian?
                              ForemanMaintain::RepositoryManager::Apt.new
                            else
                              raise 'No supported repository manager was found'
                            end
  end
end
