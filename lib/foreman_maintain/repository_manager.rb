require 'foreman_maintain/repository_manager/el'
include ForemanMaintain::Concerns::OsFacts
module ForemanMaintain
  def self.repository_manager
    @repository_manager ||= if el?
                              ForemanMaintain::RepositoryManager::El.new
                            elsif debian?
                              raise 'Not implemented!'
                            else
                              raise 'No supported repository manager was found'
                            end
  end
end
