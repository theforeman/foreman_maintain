class Checks::CheckForNewerPackages < ForemanMaintain::Check
  metadata do
    label :check_for_newer_packages
    description 'Check for newer packages and optionally ask for confirmation if not found.'

    param :packages,
          'package names to validate',
          :required => true
    param :manual_confirmation_version,
          'Version of satellite (6.9) to ask the user if they are on the latest minor release of.',
          :required => false
    manual_detection
  end

  def run
    check_for_package_update
    if @manual_confirmation_version
      question = 'Confirm that you are running the latest minor release of Satellite '\
                "#{@manual_confirmation_version}"
      answer = ask_decision(question, actions_msg: 'y(yes), q(quit)')
      abort! if answer != :yes
    end
  end

  def check_for_package_update
    exit_status, output = ForemanMaintain.package_manager.check_update(packages: @packages,
                                                                       with_status: true)
    packages_with_updates = []
    if exit_status == 100
      packages_with_updates = compare_pkg_versions(output).select do |_, result|
        result == -1
      end.keys
    end

    unless packages_with_updates.empty?
      failure_message = 'An update is available for package(s): '\
                        "#{packages_with_updates.join(',')}. Please update before proceeding!"
      fail! failure_message
    end
  end

  def packages_and_versions(output)
    pkgs_versions = {}
    pkg_details = output.split("\n\n")[1].split
    @packages.each do |pkg|
      pkg_details.each_with_index do |ele, index|
        next unless ele.start_with?(pkg)
        pkgs_versions[pkg] = version(pkg_details[index + 1].split('-').first)
        break
      end
    end
    pkgs_versions
  end

  def compare_pkg_versions(output)
    compare_pkg_versions = {}
    packages_and_versions = packages_and_versions(output)
    pkg_versions610 = { 'python3-pulp-2to3-migration' => version('0.12'),
                        'tfm-rubygem-katello' => version('4.1') }
    packages_and_versions.each do |name, version|
      compare_pkg_versions[name] = version.<=>(pkg_versions610[name])
    end
    compare_pkg_versions
  end
end
