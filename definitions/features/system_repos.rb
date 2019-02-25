class Features::SystemRepos < ForemanMaintain::Feature
  metadata do
    label :system_repos
    description 'Feature for operations on yum repositories of system'
  end

  def upstream_repos
    repositories = {}
    enabled_repos_hash.each do |repo, url|
      upstream_repo_urls.each do |regex|
        repositories[repo] = url if url =~ regex
      end
    end
    repositories
  end

  def enabled_repos_hash
    repos = execute("yum repolist enabled -d 6 -e 0 2> /dev/null | grep -E 'Repo-id|Repo-baseurl'")
    return {} if repos.empty?

    Hash[*repos.delete!(' ').split("\n")]
  end

  def upstream_repos_ids
    trim_repoids(upstream_repos.keys)
  end

  def disable_repos(repo_ids)
    execute!("yum-config-manager --disable #{repo_ids.join(',')}")
  end

  private

  def trim_repoids(repos)
    repos.map { |r| r.gsub(%r{Repo-id:|\/+\w*}, '') }
  end

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
