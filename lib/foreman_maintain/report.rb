module ForemanMaintain
  class Report < Executable
    include Concerns::Logger
    include Concerns::SystemHelpers
    include Concerns::Metadata
    include Concerns::Finders

    attr_accessor :data

    def sql_count(sql)
      feature(:foreman_database).query(sql).first['count'].to_i
    end

    def run
      raise NotImplementedError
    end

    # internal method called by executor
    def __run__(execution)
      super
    rescue Error::Fail => e
      set_fail(e.message)
    rescue Error::Warn => e
      set_warn(e.message)
    end
  end
end
