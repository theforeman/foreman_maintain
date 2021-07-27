module Checks::Puppet
  class WarnAboutPuppetRemoval < ForemanMaintain::Check
    metadata do
      description 'Warn about Puppet content removal prior to 6.10 upgrade'
      label :warn_before_puppet_removal
      confine do
        feature(:instance).downstream &&
          feature(:instance).downstream.current_minor_version == '6.9'
      end
    end

    def run
      message = "Puppet repositories found!\n"\
                "Upgrading to 6.10 will delete the Puppet repositories\n"\
                "if any of the following conditions are met,\n"\
                "1. Any Puppet repositories in Library lifecycle environment.\n"\
                "2. Unpublished content view's Puppet repositories.\n\n"\
                "Note: Any Puppet content that is in use by hosts will not be deleted.\n"\
                "After the upgrade, hosts will continue to use the Puppet modules,\n"\
                'but future Puppet content management '\
                "must be handled outside of the Satellite!\n\n"\
                'Do you want to proceed?'
      if puppet_repos_available?
        answer = ask_decision(message, actions_msg: 'y(yes), n(no)')
        exit 0 unless answer == :yes
      end
    end

    def puppet_repos_available?
      hammer_cmd = '--output json repository list --fields name --content-type puppet'
      puppet_repos = feature(:hammer).run(hammer_cmd)
      !JSON.parse(puppet_repos).empty?
    end
  end
end
