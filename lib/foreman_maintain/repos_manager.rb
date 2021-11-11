require 'foreman_maintain/repos_manager/el'
include ForemanMaintain::Concerns::OsFacts
module ForemanMaintain
  def self.repos_manager
    @repos_manager ||= if el?
                         ForemanMaintain::ReposManager::El.new
                       elsif debian?
                         raise 'Not implemented!'
                       else
                         raise 'No supported repos manager was found'
                       end
  end
end
