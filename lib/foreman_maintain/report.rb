module ForemanMaintain
  class Report < Executable
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_accessor :data

    def sql_count(sql, column: '*', cte: '')
      sql_as_count("COUNT(#{column})", sql, cte: cte)
    end

    def sql_as_count(selection, sql, cte: '')
      query = "#{cte} SELECT #{selection} AS COUNT FROM #{sql}"
      feature(:foreman_database).query(query).first['count'].to_i
    end

    def sql_setting(name)
      sql = "SELECT value FROM settings WHERE name = '#{name}'"
      result = feature(:foreman_database).query(sql).first
      (result || {})['value']
    end

    def table_exists(table)
      sql_count("information_schema.tables WHERE table_name = '#{table}'").positive?
    end

    def run
      raise NotImplementedError
    end

    # internal method called by executor
    def __run__(execution)
      super
    rescue Error::Fail => e
      set_fail(e.message)
    rescue StandardError => e
      set_warn(e.message)
    end
  end
end
