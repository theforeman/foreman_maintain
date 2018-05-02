module Checks::Mongo
  class ToolsInstalled < ForemanMaintain::Check
    metadata do
      manual_detection
      description 'Checks whether the tools for Mongo DB are installed'
      for_feature :mongo
    end

    def run
      if feature(:mongo).server_version =~ /^3\.4/
        tools_pkg = 'rh-mongodb34-mongo-tools'
        result = find_package(tools_pkg)
      else
        result = execute?('which mongodump')
        tools_pkg = 'mongodb'
      end
      handle_result(result, tools_pkg)
    end

    private

    def handle_result(result, tools_pkg)
      assert(result,
             "#{tools_pkg} was not found among installed package.\nThis package is needed to " \
               'do various operations such as backup, restore and import with Mongo DB.',
             :next_steps => [
               Procedures::Packages::Install.new(:packages => [tools_pkg])
             ])
    end
  end
end
