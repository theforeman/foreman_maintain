module ForemanMaintain
  module Cli
    class PrebuildBashCompletionCommand < Base
      def execute
        comp_map = ForemanMaintain::Cli::MainCommand.completion_map
        File.write(ForemanMaintain.config.completion_cache, comp_map.to_yaml)
      end
    end
  end
end
