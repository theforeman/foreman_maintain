class Features::UpstreamRepos < ForemanMaintain::Feature
  metadata do
    label :upstream_repos
    description 'Feature for upstream repositories'
  end

  def upstream_repos
    repositories = {}
    repos_manager.enabled_repos_hash.each do |repo, url|
      upstream_repo_urls.each do |regex|
        repositories[repo] = url if url =~ regex
      end
    end
    repositories
  end

  private

  def upstream_repo_urls
    repo_urls = { :Foreman => %r{yum.theforeman.org\/},
                  :Katello => %r{fedorapeople.org\/groups\/katello\/releases\/yum\/[\/|\w|.]*} }
    [/#{repo_urls[:Foreman]}+releases/,
     /#{repo_urls[:Foreman]}+plugins/,
     /#{repo_urls[:Katello]}+katello/,
     /#{repo_urls[:Katello]}+client/,
     /#{repo_urls[:Katello]}+candlepin/,
     /#{repo_urls[:Katello]}+pulp/,
     %r{yum.puppetlabs.com\/el\/[\w|\/|\.]*\/x86_64},
     %r{repos.fedorapeople.org\/repos\/pulp\/[\/|\w|.]*\/x86_64}]
  end
end
