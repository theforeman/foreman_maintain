require 'foreman_maintain/cli/advanced/procedure/abstract_by_tag_command'

module ForemanMaintain
  module Cli
    module Procedure
      class ByTagCommand < Base
        available_tags(ForemanMaintain.available_procedures(nil)).each do |tag|
          klass = Class.new(AbstractByTagCommand) do
            tag_params_to_options(tag)
            interactive_option
          end
          procedures = ForemanMaintain.available_procedures(:tags => tag).map do |procedure|
            procedure.label.to_s
          end

          subcommand(dashize(tag), "Run procedures tagged ##{tag} #{procedures}", klass)
        end

        def execute
          puts help
        end

        def help
          if self.class.recognised_subcommands.empty?
            warn 'WARNING: There were no tags found in procedures'
          end
          super
        end
      end
    end
  end
end
