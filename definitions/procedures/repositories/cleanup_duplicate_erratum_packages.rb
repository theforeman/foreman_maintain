module Procedures::Repositories
  class CleanupDuplicateErratumPackages < ForemanMaintain::Procedure
    metadata do
      description 'Cleanup duplicate erratum packages'
      confine do
        feature(:katello)
      end
    end

    def run
      puts "This may take a while to complete on large databases..."
      execute!('foreman-rake katello:cleanup_duplicate_erratum_packages')
      puts "Duplicate erratum package cleanup completed successfully"
    end
  end
end
