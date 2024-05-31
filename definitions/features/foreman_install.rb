class Features::ForemanInstall < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Upstream
  include ForemanMaintain::Concerns::Versions

  metadata do
    label :foreman_install

    confine do
      !feature(:instance).downstream && feature(:foreman_server)
    end
  end

  def target_version
    '3.11'
  end

  def current_version
    @current_version ||= package_version(package_name)
  end

  def package_name
    'foreman'
  end
end
