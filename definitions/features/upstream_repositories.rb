class Features::UpstreamRepositories < ForemanMaintain::Feature
  metadata do
    label :upstream_repositories
    description 'Feature for operations on upstream repositories'
  end

  def repoids_and_urls
    repoids_and_urls = {}
    repository_manager.enabled_repos_hash.each do |repo, url|
      repo_urls.each do |regex|
        repoids_and_urls[repo] = url if url =~ regex
      end
    end
    repoids_and_urls
  end

  private

  def repo_urls
    [%r{yum.theforeman.org\/*},
     %r{yum.puppetlabs.com\/el\/[\w|\/|\.]*\/x86_64}]
  end
end
