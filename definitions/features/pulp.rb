class Features::Pulp < ForemanMaintain::Feature
  metadata do
    label :pulp

    confine do
      find_package('pulp-server')
    end
  end
end
