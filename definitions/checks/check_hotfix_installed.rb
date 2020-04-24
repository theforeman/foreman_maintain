class Checks::CheckHotfixInstalled < ForemanMaintain::Check
  metadata do
    label :check_hotfix_installed
    description 'Check to verify if any hotfix installed on system'
    tags :pre_upgrade
    preparation_steps do
      [Checks::Repositories::CheckNonRhRepository.new,
       Procedures::Packages::Install.new(:packages => %w[yum-utils])]
    end

    confine do
      feature(:instance).downstream
    end
  end

  def run
    if feature(:instance).downstream.subscribed_using_activation_key?
      skip "Your system is subscribed using custom activation key. Hotfixes can't be detected."
    else
      with_spinner('Checking for presence of hotfix(es). It may take some time to verify.') do
        hotfix_rpmlist = find_hotfix_packages
        installed_pkg_list = installed_packages
        files_modifications = installed_pkg_list.flat_map { |pkg| modified_files(pkg) }
        assert(hotfix_rpmlist.empty? && files_modifications.empty?,
               warning_message(hotfix_rpmlist, files_modifications),
               :warn => true)
      end
    end
  end

  private

  def modified_files(package)
    changed_files = []
    IO.popen(['rpm', '-V', package]) do |pipe|
      pipe.each do |line|
        arr_output = line.chomp.split
        flags = arr_output.first
        filename = arr_output.last
        changed_files << filename if flags.include?('5') && filename =~ /\.(rb|py|erb|js)$/
      end
    end
    changed_files
  end

  def installed_packages
    packages = []
    repoquery_cmd = execute!('which repoquery')
    IO.popen([repoquery_cmd, '-a', '--installed', '--qf', '%{ui_from_repo} %{nvra}']) do |io|
      io.each do |line|
        repo, pkg = line.chomp.split
        packages << pkg if /satellite|rhscl/ =~ repo[1..-1].downcase
      end
    end
    packages
  end

  def find_hotfix_packages
    output = execute!('rpm -qa release="*HOTFIX*"').strip
    return [] if output.empty?

    output.split("\n")
  end

  def warning_message(hotfix_rpmlist, files_modified)
    message = "\n"
    unless hotfix_rpmlist.empty?
      message += msg_for_hotfix_rpms(hotfix_rpmlist)
    end
    unless files_modified.empty?
      message += msg_for_modified_files(files_modified)
    end
    message += "\n\n*** WARNING: Before update make sure the updated packages contain"\
      " the listed modifications\n"\
      "*** otherwise these fixes will be lost. \n"\
      '*** It is also recommended to backup the modified files prior update.'
    message
  end

  def msg_for_hotfix_rpms(rpms_list)
    message = "HOTFIX rpm(s) applied on this system:\n"
    message += rpms_list.join(',')
    message
  end

  def msg_for_modified_files(files_modified)
    message = "\n\nFound #{files_modified.length} file(s) modified on this system.\n"
    message += files_modified.join("\n")
    message
  end
end
