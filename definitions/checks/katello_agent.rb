class Checks::CheckKatelloAgentEnabled < ForemanMaintain::Check
  metadata do
    label :check_katello_agent_enabled
    description 'Check whether the katello-agent feature is enabled before upgrading'
    tags :pre_upgrade

    confine do
      !feature(:capsule)
    end
  end

  def run
    instance_name = feature(:instance).downstream ? "Satellite" : "Katello"
    instance_version = feature(:instance).downstream ? "6.15" : "4.10"
    installer_command = feature(:instance).downstream ? "satellite-installer" : "foreman-installer"
    maintain_command = feature(:instance).downstream ? "satellite-maintain" : "foreman-maintain"

    assert(
      !katello_agent_enabled?,
      "The katello-agent feature is enabled on this system. As of #{instance_name}"\
      " #{instance_version}, katello-agent is removed and will no longer function."\
      " Before proceeding with the upgrade, you should ensure that you have deployed"\
      " and configured an alternative tool for remote package management and patching"\
      " for content hosts, such as Remote Execution (REX) with pull-based transport."\
      " See the Managing Hosts guide in the #{instance_name} documentation for more info."\
      " Disable katello-agent with the command"\
      " `#{installer_command} --foreman-proxy-content-enable-katello-agent false`"\
      " before proceeding with the upgrade. Alternatively, you may skip this check and proceed by"\
      " running #{maintain_command} again with the `--whitelist` option, which will automatically"\
      " uninstall katello-agent."
    )
  end

  private

  def katello_agent_enabled?
    feature(:installer).answers['foreman_proxy_content']['enable_katello_agent']
  end
end
