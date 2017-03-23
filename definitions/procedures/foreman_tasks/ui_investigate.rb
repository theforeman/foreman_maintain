require 'cgi'
module Procedures::ForemanTasks
  class UiInvestigate < ForemanMaintain::Procedure
    metadata do
      for_feature :foreman_tasks
      description 'investigate the tasks via UI'
    end

    attr_reader :search_query

    def initialize(options = {})
      options = options.dup
      @search_query = options.delete('search_query') || ''
      raise ArgumentError, "Unexpected keys #{options.keys}" unless options.keys.empty?
    end

    def run
      ask(<<MESSAGE)
Go to https://#{hostname}/foreman_tasks/tasks?search=#{CGI.escape(search_query)}
press ENTER after the paused tasks are resolved.
MESSAGE
    end
  end
end
