module ForemanMaintain::Scenarios
  class SelfUpgradeBase < ForemanMaintain::Scenario
    include ForemanMaintain::Concerns::Downstream
    include ForemanMaintain::Concerns::Versions

    def target_version
      @target_version ||= current_version.bump
    end

    def current_version
      feature(:instance).downstream.current_minor_version
    end

    def maintenance_repo_label
      @maintenance_repo_label ||= context.get(:maintenance_repo_label)
    end

    def maintenance_repo_id(version)
      if maintenance_repo_label
        return maintenance_repo_label
      elsif (repo = ENV['MAINTENANCE_REPO_LABEL'])
        return repo unless repo.empty?
      end

      maintenance_repo(version)
    end

    def maintenance_repo(version)
      if el7?
        "rhel-#{el_major_version}-server-satellite-maintenance-#{version}-rpms"
      else
        "satellite-maintenance-#{version}-for-rhel-#{el_major_version}-x86_64-rpms"
      end
    end

    def use_rhsm?
      return false if maintenance_repo_label

      if (repo = ENV['MAINTENANCE_REPO_LABEL'])
        return false unless repo.empty?
      end

      true
    end

    def req_repos_to_update_pkgs
      if use_rhsm?
        main_rh_repos + [maintenance_repo_id(target_version)]
      else
        [maintenance_repo_id(target_version)]
      end
    end
  end

  class SelfUpgrade < SelfUpgradeBase
    metadata do
      label :self_upgrade_foreman_maintain
      description "Enables the specified version's maintenance repository and,"\
  								"\nupdates the satellite-maintain packages"
      manual_detection
    end

    def compose
      if check_min_version('foreman', '2.5') || check_min_version('foreman-proxy', '2.5')
        pkgs_to_update = %w[satellite-maintain rubygem-foreman_maintain]
        yum_options = req_repos_to_update_pkgs.map do |id|
          "--enablerepo=#{id}"
        end
        add_step(Procedures::Packages::Update.new(packages: pkgs_to_update, assumeyes: true,
                                                  yum_options: yum_options))
      end
    end
  end
end
