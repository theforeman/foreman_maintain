module Procedures::Packages
  class UpdateCollections < ForemanMaintain::Procedure
    metadata do
      param :collections, 'List of collections to upgrade', :array => true,
                                                            :default => %w[centos-release-scl-rh
                                                                           foreman-release-scl]
      param :assumeyes, 'Do not ask for confirmation'

      confine do
        package_manager.class <= ForemanMaintain::PackageManager::Yum
      end
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes
      package_manager.update(@collections, :assumeyes => assumeyes_val)
      package_manager.clean_cache
    end

    def description
      "Upgrade software collection(s) #{@collections.join(', ')}"
    end
  end
end
