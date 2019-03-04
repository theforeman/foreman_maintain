class Features::PackageManager < ForemanMaintain::Feature
  metadata do
    label :package_manager
    confine do
      true
    end
  end
end
