require 'foreman_maintain/repository_manager/el'
module ForemanMaintain
  extend ForemanMaintain::Concerns::OsFacts

  def self.repository_manager
    @repository_manager ||= if el?
                              ForemanMaintain::RepositoryManager::El.new
                            elsif debian_or_ubuntu?
                              raise 'Not implemented!'
                            else
                              raise 'No supported repository manager was found'
                            end
  end
end
