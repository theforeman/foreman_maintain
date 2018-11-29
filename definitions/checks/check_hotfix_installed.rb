class Checks::CheckHotfixInstalled < ForemanMaintain::Check
  metadata do
    label :check_hotfix_installed
    description 'Check to verify if any hotfix installed on system'
    preparation_steps do
      Procedures::Packages::Install.new(:packages => %w[yum-utils])
    end

    confine do
      feature(:downstream)
    end

    # param :version,
    #      'Version for which repositories needs to be consider',
    #      :required => true

    # manual_detection
  end

  def run
    # TODO: Remove this part as it is only for testing changes locally
    @version = '6.2'
    if feature(:downstream) && feature(:downstream).subscribed_using_activationkey?
      skip 'Your system is subscribed using custom activationkey'
    else
      with_spinner('Checking for presence of hotfix(es). It may takes some time to verify.') do
        hotfix_rpmlist = []

        hotfix_rpmlist = find_hotfix_rpms_installed if feature(:downstream)
        files_modifications = rpm_verify_command(@version)
        assert(hotfix_rpmlist.empty? && files_modifications.empty?,
               warning_message(hotfix_rpmlist, files_modifications))
      end
    end
  end

  private

  def warning_message(hotfix_rpmlist, files_modifications)
    message = "\n"
    unless hotfix_rpmlist.empty?
      message += "Found below HOTFIX rpm(s) applied on this system.\n"
      message += hotfix_rpmlist
    end
    unless files_modifications.empty?
      message += "Found #{files_modifications.length} file(s) modified on this system.\n"
      if files_modifications.length > 10
        message += 'Here, it shows only 10 records. For complete result, please check a log file.'
      end
      message += files_modifications[0..9].join("\n")
    end
    message += "\nBefore continuing upgrade, please verify above hotfix(es) details\n"
    message
  end

  # only for downstream
  def find_hotfix_rpms_installed
    cmd = "rpm -qa 'HOTFIXRHBZ*'"
    output = execute!(cmd).strip
    return [] if output.empty?

    output.split("\n")
  end

  def rpm_verify_command(version)
    cmd = "rpm -V `#{find_installed_packages(version)}` | grep -E '#{regex_for_files_check}'"
    cmd += " | awk '{print $2}' "
    return [] unless execute?(cmd) # handle echo $? = 1

    output = execute!(cmd).strip
    return [] if output.empty?

    output.strip.split("\n")
  end

  def find_installed_packages(version)
    repolist_regexstr = feature(:downstream).repolist_for_hotfix_verify(version).join('|')

    # IO.popen(" awk '/#{repolist_regexstr}/ {print $2}'", "w").write (
    #  IO.popen("repoquery -a --installed --qf '%{ui_from_repo} %{name}'").read
    # )

    repoquery_cmd = "repoquery -a --installed --qf '%{ui_from_repo} %{name}'"
    repoquery_cmd += " | awk '/#{repolist_regexstr}/ {print $2}'"
    execute!(repoquery_cmd)
    repoquery_cmd
  end

  def regex_for_files_check
    '^(..5....T.){1}(.{2}[^c])+.+\.(rb|py|erb|js)$'
  end
end
