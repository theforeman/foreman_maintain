module Checks::Container
  class PodmanLogin < ForemanMaintain::Check
    metadata do
      for_feature :satellite
      confine do
        feature(:satellite)&.connected? && feature(:containers)
      end
      description 'Check whether podman is logged in to registry'
      tags :pre_upgrade
    end

    def run
      login_status, _output = execute_with_status('podman login --get-login registry.redhat.io')
      assert(
        login_status == 0,
        failure_message
      )
    end

    private

    def failure_message
      <<~MSG
        You are using containers from registry.redhat.io,
        but your system is not logged in to the registry, or the login expired.
        Please login to registry.redhat.io.
      MSG
    end
  end
end
