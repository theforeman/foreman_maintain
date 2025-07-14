module ForemanMaintain
  module Concerns
    module Downstream
      SATELLITE_MAINTAIN_CONFIG = '/usr/share/satellite-maintain/config.yml'.freeze
      REDHAT_REPO_FILE = '/etc/yum.repos.d/redhat.repo'.freeze

      def current_version
        raise NotImplementedError
      end

      def repository_manager
        ForemanMaintain.repository_manager
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
          repository_manager.rhsm_disable_repos(['*'])
          repository_manager.rhsm_enable_repos(rh_repos(version))
        end
      end

      def absent_repos(version)
        repos_required = rh_repos(version)
        repos_found = repos_required & repository_manager.rhsm_list_repos.keys
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

      def satellite_maintain_target_version
        satellite_maintain_config['current_satellite_version']
      end

      def satellite_upgrade_allowed?
        current_minor_version == satellite_maintain_config['previous_satellite_version'] ||
          ForemanMaintain.upgrade_in_progress == satellite_maintain_target_version
      end

      def connected?
        File.exist?(REDHAT_REPO_FILE) && File.new(REDHAT_REPO_FILE).read.include?('https://cdn.redhat.com')
      end

      private

      def satellite_maintain_config
        if File.exist?(SATELLITE_MAINTAIN_CONFIG)
          YAML.load_file(SATELLITE_MAINTAIN_CONFIG)
        else
          raise "Could not load satellite-maintain configuration file #{SATELLITE_MAINTAIN_CONFIG}."
        end
      end

      def rh_repos(server_version)
        server_version = version(server_version)
        rh_repos = main_rh_repos
        server_version_full = "#{server_version.major}.#{server_version.minor}"
        rh_repos.concat(product_specific_repos(server_version_full))
        rh_repos
      end

      def product_specific_repos(full_version)
        repos = ["#{package_name}-#{full_version}-for-rhel-#{el_major_version}-x86_64-rpms"]
        repos.concat(common_repos(full_version))
      end

      def common_repos(full_version)
        ["satellite-maintenance-#{full_version}-for-rhel-#{el_major_version}-x86_64-rpms"]
      end

      def main_rh_repos
        [
          "rhel-#{el_major_version}-for-x86_64-baseos-rpms",
          "rhel-#{el_major_version}-for-x86_64-appstream-rpms",
        ]
      end
    end
  end
end
