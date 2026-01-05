class Checks::CheckSubscriptionManagerRelease < ForemanMaintain::Check
  metadata do
    label :check_subscription_manager_release
    description 'Check if subscription-manager release is not set to a minor version'

    confine do
      feature(:instance).downstream
    end
  end

  def run
    status, output = execute_with_status('LC_ALL=C subscription-manager release --show')

    # If command fails (subscription-manager not installed or system not registered), pass the check
    return if status != 0

    assert(valid_release?(output), error_message(output))
  end

  private

  def valid_release?(output)
    # Valid formats: "Release not set" or "Release: X" where X is a major version without dots
    return true if output == 'Release not set'
    return true if /^Release:\s+\d+$/.match?(output)

    false
  end

  def extract_release(output)
    match = output.match(/^Release:\s+(.+)$/)
    match ? match[1] : output
  end

  def error_message(output)
    subman_release = extract_release(output)
    "Your system is configured to use RHEL #{subman_release}, but Satellite is only "\
    "supported on the latest RHEL. Please unset the release in subscription-manager by "\
    "calling `subscription-manager release --unset`."
  end
end
