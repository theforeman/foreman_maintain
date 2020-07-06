class Checks::EnvProxy < ForemanMaintain::Check
  metadata do
    label :env_proxy
    tags :env_proxy
    description 'Check if proxy is set in ENV which shouldn\'t be the case'
  end

  def run
    variables = %w[http_proxy https_proxy HTTP_PROXY HTTPS_PROXY]
    has_proxy_set = true if variables.map { |variable| ENV[variable] }.compact.any?
    assert(has_proxy_set, 'Global HTTP(S) proxy in environment (env) is set. Please unset first!')
  end
end
