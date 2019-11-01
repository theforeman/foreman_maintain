module AssumeFeatureDependenciesHelper
  def assume_satellite_present(&block)
    PackageManagerTestHelper.assume_package_exist('satellite')
    assume_feature_present(:satellite) unless block_given?
    assume_feature_present(:satellite, &block)
  end
end
