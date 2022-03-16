module Procedures::Content
  class FixPulpcoreArtifactOwnership < ForemanMaintain::Procedure
    metadata do
      description 'Fix Pulpcore artifact ownership to be pulp:pulp'
      param :assumeyes, 'Do not ask for confirmation', :default => false

      confine do
        check_min_version(foreman_plugin_name('katello'), '4.0')
      end
    end

    def ask_to_proceed
      question = "\nWARNING: Only proceed if your system is fully switched to Pulp 3.\n"
      question += "\n\nDo you want to proceed?"
      answer = ask_decision(question, actions_msg: 'y(yes), q(quit)')
      abort! if answer != :yes
    end

    def run
      assumeyes_val = @assumeyes.nil? ? assumeyes? : @assumeyes

      ask_to_proceed unless assumeyes_val

      with_spinner('Updating artifact ownership for Pulp 3') do |spinner|
        spinner.update('# chown -hR pulp.pulp /var/lib/pulp/media/artifact')
        FileUtils.chown_R 'pulp', 'pulp', '/var/lib/pulp/media/artifact'
      end
    end
  end
end
