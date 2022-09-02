module ForemanMaintain
  module Concerns
    module Upstream
      include Concerns::ForemanAndKatelloVersionMap

      def server_url
        if el?
          'https://yum.theforeman.org/'
        elsif debian_or_ubuntu?
          'https://deb.theforeman.org/'
        else
          raise 'Unknown operating system detected!'
        end
      end

      def foreman_release_pkg_url(version)
        if el?
          "#{server_url}releases/#{version}/#{el_short_name}/x86_64/foreman-release.rpm"
        elsif debian_or_ubuntu?
          "#{server_url}pool/#{os_version_codename}/#{version}"\
          '/f/foreman-release/foreman-release.deb'
        else
          raise 'Unknown operating system detected!'
        end
      end

      def katello_pkgs_url(katello_version)
        "#{server_url}katello/#{katello_version}/katello/#{el_short_name}/x86_64/"
      end

      def katello_release_pkg(version)
        "#{katello_pkgs_url(katello_version_by_foreman(version))}katello-repos-latest.rpm"
      end

      def update_release_pkg_el(pkg_url)
        package_manager.install(pkg_url, assumeyes: true)
      end

      def update_release_pkg_deb(pkg_url)
        Dir.mktmpdir do |dir|
          release_file_path = "#{dir}/foreman-release.deb"
          exit_status, = execute_with_status("wget -q -O #{release_file_path} #{pkg_url}")
          if exit_status == 0
            package_manager.install(release_file_path, assumeyes: true)
          else
            warn! "Couldn't install Foreman release package: #{pkg_url}"
          end
        end
      end

      def use_activation_key(activation_key, org)
        org_options = org ? %(--org #{shellescape(org)}) : ''
        execute!(%(subscription-manager register #{org_options}\
                    --activationkey #{shellescape(activation_key)} --force))
      end

      def update_foreman_release_pkg(version)
        pkg_url = foreman_release_pkg_url(version)
        if el?
          update_release_pkg_el(pkg_url)
        elsif debian_or_ubuntu?
          update_release_pkg_deb(pkg_url)
        end
      end

      def update_katello_release_pkg(version)
        if feature(:katello)
          pkg_url = katello_release_pkg(version)
          update_release_pkg_el(pkg_url)
        end
      end

      def setup_repositories(version)
        # Documentation needs update with respect to new env vars
        activation_key = ENV['ACTIVATION_KEY']
        org = ENV['FOREMAN_ORG']
        if activation_key
          use_activation_key(activation_key, org)
        else
          update_foreman_release_pkg(version)
          update_katello_release_pkg(version)
        end
      end

      def repoids_and_urls
        repoids_and_urls = {}
        repository_manager.enabled_repos.each do |repo, url|
          repo_urls.each do |regex|
            repoids_and_urls[repo] = url if url =~ regex
          end
        end
        repoids_and_urls
      end

      private

      def repo_urls
        [%r{yum.theforeman.org\/*},
         %r{yum.puppetlabs.com\/*}]
      end
    end
  end
end
