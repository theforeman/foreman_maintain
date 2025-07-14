class Features::Containers < ForemanMaintain::Feature
  metadata do
    label :containers
    confine do
      Dir.exist?('/etc/containers/systemd') && !Dir.empty?('/etc/containers/systemd')
    end
  end
end
