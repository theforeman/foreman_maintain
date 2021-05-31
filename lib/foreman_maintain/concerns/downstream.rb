module ForemanMaintain
  module Concerns
    module Downstream
      def current_version
        raise NotImplementedError
      end

      def less_than_version?(version)
        Gem::Version.new(current_version) < Gem::Version.new(version)
      end

      def at_least_version?(version)
        Gem::Version.new(current_version) >= Gem::Version.new(version)
      end

      def current_minor_version
        current_version.to_s[/^\d+\.\d+/]
      end

      # TODO: Modify activation_key changes as per server
      def setup_repositories(version)
        activation_key = ENV['EXTERNAL_SAT_ACTIVATION_KEY']
        org = ENV['EXTERNAL_SAT_ORG']
        if activation_key
          org_options = org ? %(--org #{shellescape(org)}) : ''
          execute!(%(subscription-manager register #{org_options}\
                      --activationkey #{shellescape(activation_key)} --force))
        else
          execute!(%(subscription-manager repos --disable '*'))
          enable_options = rh_repos(version).map { |r| "--enable=#{r}" }.join(' ')
          execute!(%(subscription-manager repos #{enable_options}))
        end
      end

      def absent_repos(version)
        all_repo_lines = execute(%(LANG=en_US.utf-8 subscription-manager repos --list 2>&1 | ) +
                                  %(grep '^Repo ID:')).split("\n")
        all_repos = all_repo_lines.map { |line| line.split(/\s+/).last }
        repos_required = rh_repos(version)
        repos_found = repos_required & all_repos
        repos_required - repos_found
      end

      def rhsm_refresh
        execute!(%(subscription-manager refresh))
      end

      # TODO: Verify this is valid for capsule?
      def subscribed_using_activation_key?
        ENV['EXTERNAL_SAT_ACTIVATION_KEY'] && ENV['EXTERNAL_SAT_ORG']
      end

      def package_name
        raise NotImplementedError
      end

      def fm_pkg_and_cmd_name
        %w[satellite-maintain satellite-maintain]
      end

      private

      def rh_repos(server_version)
        server_version = version(server_version)
        rh_repos = main_rh_repos
        server_version_full = "#{server_version.major}.#{server_version.minor}"
        rh_repos.concat(product_specific_repos(server_version_full))
        if server_version > version('6.3')
          rh_repos << ansible_repo(server_version)
        end

        rh_repos
      end

      def ansible_repo(server_version)
        if server_version >= version('6.8')
          "rhel-#{el_major_version}-server-ansible-2.9-rpms"
        elsif server_version >= version('6.6')
          "rhel-#{el_major_version}-server-ansible-2.8-rpms"
        elsif server_version >= version('6.4')
          "rhel-#{el_major_version}-server-ansible-2.6-rpms"
        end
      end

      def product_specific_repos(full_version)
        repos = []
        repos << if ENV['FOREMAN_MAINTAIN_USE_BETA'] == '1'
                   "rhel-server-#{el_major_version}-#{package_name}-6-beta-rpms"
                 else
                   "rhel-#{el_major_version}-server-#{package_name}-#{full_version}-rpms"
                 end
        repos << puppet4_repo(full_version) unless puppet4_repo(full_version).nil?
        repos.concat(common_repos(full_version))
      end

      def puppet4_repo(full_version)
        if current_minor_version == '6.3' && full_version.to_s != '6.4' && (
          feature(:puppet_server) && feature(:puppet_server).puppet_version.major == 4)
          "rhel-#{el_major_version}-server-#{package_name}-tools-6.3-puppet4-rpms"
        end
      end

      def common_repos(full_version)
        repos_arrary = if ENV['FOREMAN_MAINTAIN_USE_BETA'] == '1'
                         ["rhel-#{el_major_version}-server-satellite-maintenance-6-beta-rpms",
                          "rhel-#{el_major_version}-server-satellite-tools-6-beta-rpms"]
                       else
                         ["rhel-#{el_major_version}-server-satellite-maintenance-6-rpms",
                          "rhel-#{el_major_version}-server-satellite-tools-#{full_version}-rpms"]
                       end

        return repos_arrary.first(1) if feature(:satellite)

        repos_arrary
      end

      def main_rh_repos
        ["rhel-#{el_major_version}-server-rpms",
         "rhel-server-rhscl-#{el_major_version}-rpms"]
      end

      def version_from_source
        raise NotImplementedError
      end
    end
  end
end
