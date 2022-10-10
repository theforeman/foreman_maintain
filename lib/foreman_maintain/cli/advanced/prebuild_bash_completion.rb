require 'fileutils'

module ForemanMaintain
  module Cli
    class PrebuildBashCompletionCommand < Base
      include ForemanMaintain::Concerns::SystemHelpers
      def execute
        comp_map = ForemanMaintain::Cli::MainCommand.completion_map
        answers = feature(:installer).configuration[:answer_file]
        comp_map[:expire] = {
          :file => answers,
          :sha1sum => execute!("sha1sum #{answers}"),
        }
        cache_dir = File.dirname(ForemanMaintain.config.completion_cache_file)
        FileUtils.mkdir_p(cache_dir) unless File.directory?(cache_dir)
        File.write(ForemanMaintain.config.completion_cache_file, comp_map.to_yaml)
      end
    end
  end
end
