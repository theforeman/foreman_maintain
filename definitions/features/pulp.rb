class Features::Pulp < ForemanMaintain::Feature
  metadata do
    label :pulp

    confine do
      find_package('pulp-server')
    end
  end

  def services
    {
      'mongod'                   => 5,
      'squid'                    => 10,
      'pulp_workers'             => 20,
      'pulp_celerybeat'          => 20,
      'pulp_resource_manager'    => 20,
      'pulp_streamer'            => 20
    }
  end
end
