require 'test_helper'
require 'foreman_maintain/repository_manager'
module ForemanMaintain
  describe RepositoryManager::El do
    let(:repository_manager) do
      ForemanMaintain::RepositoryManager::El.new
    end

    def stub_repos
      "Repo-id     : repository-one/7Server/x86_64
      Repo-name    : The Repository One (RPMs)
      Repo-baseurl : https://abc.example.com/content/repository-one

      Repo-id      : repository-two/7Server/x86_64
      Repo-name    : The Repository Two (RPMs)
      Repo-baseurl : https://abc.example.com/content/repository-two"
    end

    it("Split repository labels by '/' and use only first part") do
      repo_hash = { 'repository-one' => 'https://abc.example.com/content/repository-one',
                    'repository-two' => 'https://abc.example.com/content/repository-two' }
      regex = /Repo-id|Repo-baseurl/
      assert_equal repo_hash, repository_manager.hash_of_repoids_urls(stub_repos, regex)
    end
  end
end
