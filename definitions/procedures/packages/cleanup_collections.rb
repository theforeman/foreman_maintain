module Procedures::Packages
  class CleanupCollections < ForemanMaintain::Procedure
    metadata do
      param :packages, 'List of packages to remove e.g. rh-ruby22\*', :array => true
      param :assumeyes, 'Do not ask for confirmation'

      confine do
        package_manager.class <= ForemanMaintain::PackageManager::Yum
      end
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      package_manager.remove(@packages, :assumeyes => assumeyes_val)
    end

    def description
      "Cleanup packges from software collection(s) #{@packages.join(', ')}"
    end
  end
end
