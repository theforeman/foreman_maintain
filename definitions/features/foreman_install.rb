class Features::ForemanInstall < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Upstream
  include ForemanMaintain::Concerns::Versions

  metadata do
    label :foreman_install

    confine do
      !feature(:instance).downstream && !feature(:katello) && feature(:foreman_server)
    end
  end
end
