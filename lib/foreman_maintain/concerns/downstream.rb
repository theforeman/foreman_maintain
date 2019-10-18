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

      private

      def rh_repos(server_version)
        server_version = version(server_version)
        rh_version_major = ForemanMaintain::Utils::Facter.os_major_release
        rh_repos = main_rh_repos(rh_version_major)

        server_version_full = "#{server_version.major}.#{server_version.minor}"
        rh_repos.concat(product_specific_repos(rh_version_major, server_version_full))

        if server_version > version('6.3')
          rh_repos << ansible_repo(server_version, rh_version_major)
        end

        rh_repos
      end

      def ansible_repo(server_version, rh_version_major)
        if server_version >= version('6.6')
          "rhel-#{rh_version_major}-server-ansible-2.8-rpms"
        elsif server_version >= version('6.4')
          "rhel-#{rh_version_major}-server-ansible-2.6-rpms"
        end
      end

      # TODO: refactoring
      def product_specific_repos(rh_version_major, full_version)
        repos = []
        repos << if ENV['FOREMAN_MAINTAIN_USE_BETA'] == '1'
                   "rhel-server-#{rh_version_major}-#{package_name}-6-beta-rpms"
                 else
                   "rhel-#{rh_version_major}-server-#{package_name}-#{full_version}-rpms"
                 end

        if current_minor_version == '6.3' && server_version.to_s != '6.4' && (
          feature(:puppet_server) && feature(:puppet_server).puppet_version.major == 4)
          # TODO: confirm repo for capsule. It might be same repo
          repos << "rhel-#{rh_version_major}-server-satellite-tools-6.3-puppet4-rpms"
        end

        repos.concat(common_repos(rh_version_major, full_version))
      end

      def common_repos(rh_version_major, full_version)
        repos_arrary = common_repos_array(rh_version_major, full_version)
        return repos_arrary.first(1) if feature(:capsule)

        repos_arrary
      end

      def common_repos_array(rh_version_major, full_version)
        ["rhel-#{rh_version_major}-server-satellite-maintenance-6#{use_beta}-rpms",
         "rhel-#{rh_version_major}-server-satellite-tools-#{full_version}#{use_beta}-rpms"]
      end

      def use_beta
        return '-beta' if ENV['FOREMAN_MAINTAIN_USE_BETA'] == '1'

        nil
      end

      def main_rh_repos(rh_version_major)
        ["rhel-#{rh_version_major}-server-rpms",
         "rhel-server-rhscl-#{rh_version_major}-rpms"]
      end

      def version_from_source
        raise NotImplementedError
      end
    end
  end
end
