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
    rescue StandardError
      nil
    end

    def sql_setting(name)
      sql = "SELECT value FROM settings WHERE name = '#{name}'"
      result = feature(:foreman_database).query(sql).first
      (result || {})['value']
    end

    def flatten(hash, prefix = '')
      hash.each_with_object({}) do |(key, value), result|
        new_key = "#{prefix}#{prefix.empty? ? '' : flatten_separator}#{key}"
        if value.is_a? Hash
          result.merge!(flatten(value, new_key))
        else
          result[new_key] = value
        end
      end
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

    def flatten_separator
      '|'
    end
  end
end
