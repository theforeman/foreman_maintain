class Procedures::InstallPackage < ForemanMaintain::Procedure
  metadata do
    param :packages, 'List of packages to install', :array => true
  end

  def run
    install_packages(@packages, :assumeyes => assumeyes?)
  end

  def necessary?
    @packages.any? { |package| package_version(package).nil? }
  end

  def description
    "Install package(s) #{@packages.join(', ')}"
  end
end
