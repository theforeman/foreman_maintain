class Checks::CheckOrganizationContentAccessMode < ForemanMaintain::Check
  metadata do
    label :check_organization_content_access_mode
    description 'Check if any organizations are using entitlement mode'

    confine do
      feature(:katello)
    end
  end

  def run
    doc_link = "https://access.redhat.com/articles/simple-content-access"

    with_spinner('Checking organization content access modes') do
      output = execute_org_check
      orgs_to_migrate = parse_orgs_to_migrate(output)

      assert(
        orgs_to_migrate.empty?,
        "\nThe following organizations are using entitlement mode:\n"\
        "#{format_orgs_to_migrate(orgs_to_migrate)}\n\n"\
        "As of Satellite 6.16, entitlement mode is removed, and these organizations"\
        " will be automatically migrated to Simple Content Access during the upgrade."\
        " Please ensure that you have reviewed the documentation and are prepared for this change."\
        " Documentation for SCA mode is available at #{doc_link}"
      )
    end
  end

  private

  # rubocop:disable Lint/InterpolationCheck
  def execute_org_check
    execute!(
      'echo "Organization.all.each ' \
      '{ |org| puts \"NONSCA: #{org.name}\" unless org.simple_content_access? }" ' \
      '| foreman-rake console'
    )
  end
  # rubocop:enable Lint/InterpolationCheck

  def parse_orgs_to_migrate(output)
    orgs = []
    output.each_line do |line|
      match = line.match(/NONSCA: (.+)/)
      if match && !match[1].strip.start_with?('#{org.name}') # rubocop:disable Lint/InterpolationCheck
        orgs << match[1].strip
      end
    end
    orgs
  end

  def format_orgs_to_migrate(orgs_to_migrate)
    orgs_to_migrate.join("\n")
  end
end
