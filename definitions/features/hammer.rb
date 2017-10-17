class Features::Hammer < ForemanMaintain::Feature
  metadata do
    label :hammer
  end

  SERVICES_MAPPING = {
    'candlepin_auth' => %w[postgresql tomcat],
    'candlepin' => %w[postgresql tomcat],
    'pulp_auth' => %w[pulp_resource_manager pulp_workers pulp_celerybeat],
    'pulp' => %w[pulp_resource_manager pulp_workers pulp_celerybeat],
    'foreman_tasks' => %w[foreman-tasks]
  }.freeze

  def hammer_ping_cmd
    cmd_output = exec_hammer_cmd('--output json ping', true)
    return init_result_obj(false, cmd_output) if cmd_output.is_a?(String)
    resources_failed = find_resources_which_failed(cmd_output.first)
    return init_result_obj if resources_failed.empty?
    services = map_resources_with_services(resources_failed)
    msg_to_show = "#{resources_failed.join(', ')} resource(s) are failing."
    init_result_obj(false, msg_to_show, services)
  end

  def find_resources_which_failed(hammer_ping_output)
    resources_failed = []
    hammer_ping_output.each do |resource, resp_obj|
      resources_failed << resource if /FAIL/ =~ resp_obj['Status']
    end
    resources_failed
  end

  private

  def map_resources_with_services(resources)
    service_names = []
    resources.each do |resource|
      service_names.concat(SERVICES_MAPPING[resource])
    end
    service_names
  end

  def init_result_obj(success_val = true, message = '', data = [])
    {
      :success => success_val,
      :message => message,
      :data => data
    }
  end

  def exec_hammer_cmd(cmd, required_json = false)
    response = ForemanMaintain::Utils::Hammer.instance.run_command(cmd)
    json_str = parse_json(response) if required_json
    json_str ? json_str : response
  end
end
