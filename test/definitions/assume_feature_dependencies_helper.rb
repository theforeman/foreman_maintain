module AssumeFeatureDependenciesHelper
  def assume_satellite_present(&block)
    assume_feature_present(:package_manager) do |feature_class|
      feature_class.any_instance.stubs(:installed? => true)
    end
    assume_feature_present(:satellite) unless block_given?

    assume_feature_present(:satellite, &block)
  end
end
