class Features::Client < ForemanMaintain::Feature
  label :client

  confine do
    # if server is not present, we assume it's client
    !feature(:server)
  end
end
