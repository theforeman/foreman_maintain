class Procedures::InstallPackage < ForemanMaintain::Procedure
  metadata do
    param :packages, 'List of packages to install', :array => true
    description 'install packages(s)'
  end

  def run
    install_packages(@packages, :assumeyes => assumeyes?)
  end

  def necessary?
    @packages.any? { |package| package_version(package).nil? }
  end

  def runtime_message
    "Install package(s) #{@packages.join(', ')}"
  end
end
