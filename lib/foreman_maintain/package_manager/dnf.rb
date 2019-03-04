module ForemanMaintain::PackageManager
  class Dnf < Yum
    def clean_cache
      dnf_action('clean', 'all')
      super
    end

    private

    def dnf_action(action, packages, assumeyes: false)
      yum_options = []
      yum_options << '-y' if assumeyes
      sys.execute!("dnf #{yum_options.join(' ')} #{action} #{packages.join(' ')}",
                   :interactive => true)
    end
  end
end
