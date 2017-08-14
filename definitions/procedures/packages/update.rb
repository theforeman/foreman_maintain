module Procedures::Packages
  class Update < ForemanMaintain::Procedure
    metadata do
      param :packages, 'List of packages to update', :array => true
      param :assumeyes, 'Do not ask for confirmation'
    end

    def run
      packages_action(:update, @packages, :assumeyes => @assumeyes.nil? ? assumeyes? : @assumeyes)
    end

    def necessary?
      @packages.any? { |package| package_version(package).nil? }
    end

    def description
      "Update package(s) #{@packages.join(', ')}"
    end
  end
end
