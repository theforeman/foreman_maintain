module ForemanMaintain
  module Concerns
    module Downstream
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

      private

      def rh_repos(server_version)
        server_version = version(server_version)
        rh_repos = main_rh_repos
        server_version_full = "#{server_version.major}.#{server_version.minor}"
        rh_repos.concat(product_specific_repos(server_version_full))
        rh_repos
      end

      def use_beta_repos?
        ENV['FOREMAN_MAINTAIN_USE_BETA'] == '1'
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

      def version_from_source
        raise NotImplementedError
      end
    end
  end
end
