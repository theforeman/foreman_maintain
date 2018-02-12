class Features::PuppetServer < ForemanMaintain::Feature
  metadata do
    label :puppet_server

    confine do
      find_package('puppetserver')
    end
  end

  def services
    { 'puppetserver' => 30 }
  end
end
