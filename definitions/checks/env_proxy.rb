class Checks::EnvProxy < ForemanMaintain::Check
  metadata do
    label :env_proxy
    tags :env_proxy
    description 'Check to make sure no HTTP(S) proxy set in ENV'
  end

  def run
    variables = %w[http_proxy https_proxy HTTP_PROXY HTTPS_PROXY]
    has_proxy_set = true if variables.map { |variable| ENV[variable] }.compact.any?
    assert(!has_proxy_set, 'Global HTTP(S) proxy in environment (env) is set. Please unset first!')
  end
end
