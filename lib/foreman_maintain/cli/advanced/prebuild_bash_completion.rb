module ForemanMaintain
  module Cli
    class PrebuildBashCompletionCommand < Base
      include ForemanMaintain::Concerns::SystemHelpers
      def execute
        comp_map = ForemanMaintain::Cli::MainCommand.completion_map
        answers = feature(:installer).configuration[:answer_file]
        comp_map[:expire] = {
          :file => answers,
          :sha1sum => execute!("sha1sum #{answers}")
        }
        File.write(ForemanMaintain.config.completion_cache, comp_map.to_yaml)
      end
    end
  end
end
