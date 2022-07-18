class Features::KatelloInstall < ForemanMaintain::Feature
  include ForemanMaintain::Concerns::Upstream
  include ForemanMaintain::Concerns::Versions

  metadata do
    label :katello_install

    confine do
      !feature(:instance).downstream && feature(:katello)
    end
  end
end
