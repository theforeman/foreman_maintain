class Checks::CheckOrganizationContentAccessMode < ForemanMaintain::Check
  metadata do
    label :check_organization_content_access_mode
    description 'Check if any organizations are using entitlement mode before upgrading'
    tags :pre_upgrade

    confine do
      feature(:katello)
    end
  end

  def run
    if feature(:instance).downstream?
      versioned_instance_name = "Satellite 6.16"
      doc_link = "https://access.redhat.com/articles/simple-content-access"
    else
      versioned_instance_name = "Katello 4.12"
      doc_link = "https://theforeman.org/plugins/katello/nightly/user_guide/simple_content_access/index.html"
    end

    with_spinner('Checking organization content access modes') do
      output = execute_rake_task
      orgs_to_migrate = parse_orgs_to_migrate(output)

      assert(
        orgs_to_migrate.empty?,
        "The following organizations are using entitlement mode:\n"\
        "#{orgs_to_migrate.join(', ')}\n"\
        "As of #{versioned_instance_name}, entitlement mode is removed, and these organizations"\
        " will be automatically migrated to Simple Content Access during the upgrade."\
        " Please ensure that you have reviewed the documentation and are prepared for this change."\
        " Documentation for SCA mode is available at #{doc_link}"
      )
    end
  end

  private

  def execute_rake_task
    execute!(
      'foreman-rake runner "puts Organization.all.map(&:simple_content_access?).count(false)"'
    )
  end

  def parse_orgs_to_migrate(output)
    orgs = []
    output.each_line do |line|
      match = line.match(/Checking content access mode for (.+)/)
      orgs << match[1] if match
    end
    orgs
  end
end
