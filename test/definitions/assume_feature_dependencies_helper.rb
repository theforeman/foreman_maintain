module AssumeFeatureDependenciesHelper
  def assume_satellite_present(&block)
    PackageManagerTestHelper.assume_package_exist('satellite')
    unless block_given?
      assume_feature_present(:satellite)
      assume_feature_present(:foreman_server)
      assume_feature_present(:katello)
      assume_feature_present(:candlepin)
      assume_feature_present(:foreman_tasks)
      assume_feature_present(:foreman_database)
    end
    assume_feature_present(:satellite, &block)
  end

  def assume_foreman_present
    PackageManagerTestHelper.assume_package_exist('foreman')
    assume_feature_present(:foreman_install)
    assume_feature_present(:foreman_server)
    assume_feature_present(:foreman_database)
  end

  def assume_katello_present
    PackageManagerTestHelper.assume_package_exist('katello')
    assume_feature_present(:foreman_server)
    assume_feature_present(:katello)
    assume_feature_present(:candlepin)
    assume_feature_present(:foreman_tasks)
    assume_feature_present(:foreman_database)
  end
end
