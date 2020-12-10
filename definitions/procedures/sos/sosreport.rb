module Procedures::Sos
  class Sosreport < ForemanMaintain::Procedure
    metadata do
      label :sos
      description 'Perform extra log collection for sosreport'
      param :exclude, 'List of actions to exclude (comma separated)'
    end

    def run
      # Put new actions here and create method below. Make sure to create
      # patch into sosreport with "--exclude new_method" as well.
      @all_actions = %w(create_directory excluded_actions)
      @excluded_actions = @exclude.split(',').map(&:strip)
      @actions = @all_actions - @excluded_actions
      @basedir = '/var/tmp/foreman-maintain-sos'
      @actions.each do |action|
        with_spinner("Performing #{action}") do
          send action.to_sym
        end
      end
    end

    def create_directory
      FileUtils.mkdir_p @basedir
    end

    def excluded_actions
      File.open('/var/tmp/foreman-maintain-sos/excluded_actions.log', 'w') do |f|
        f.puts(@excluded_actions)
      end
    end
  end
end
