module Procedures::Packages
  class Install < ForemanMaintain::Procedure
    metadata do
      param :packages, 'List of packages to install', :array => true
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      packages_action(:install, @packages, :assumeyes => @assumeyes.nil? ? assumeyes? : @assumeyes)
    end

    def necessary?
      @packages.any? { |package| package_version(package).nil? }
    end

    def description
      "Install package(s) #{@packages.join(', ')}"
    end
  end
end
