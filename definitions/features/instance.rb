class Features::Instance < ForemanMaintain::Feature
  metadata do
    label :instance
  end

  def foreman_proxy_product_name
    feature(:downstream) ? 'Capsule' : 'Foreman Proxy'
  end

  def server_product_name
    if feature(:downstream)
      'Satellite'
    elsif feature(:katello)
      'Katello'
    else
      'Foreman'
    end
  end

  def external_proxy?
    !!(feature(:foreman_proxy) && !feature(:foreman_server))
  end

  def product_name
    if external_proxy?
      foreman_proxy_product_name
    else
      server_product_name
    end
  end

  def database_local?(feature)
    !!feature(feature) && feature(feature).local?
  end

  def postgresql_local?
    database_local?(:candlepin_database) || database_local?(:foreman_database)
  end
end
