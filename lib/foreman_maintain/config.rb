module ForemanMaintain
  class Config
    attr_accessor :definitions_dirs, :log_level

    def initialize(options = {})
      @definitions_dirs = options.fetch(:definitions_dirs,
                                        [File.join(source_path, 'definitions')])
      @log_level = options.fetch(:log_level, ::Logger::ERROR)
    end

    private

    def source_path
      File.expand_path('../../..', __FILE__)
    end
  end
end
