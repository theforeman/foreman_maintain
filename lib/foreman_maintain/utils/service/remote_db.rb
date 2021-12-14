module ForemanMaintain::Utils
  module Service
    class RemoteDB < Abstract
      attr_reader :component, :db_feature
      def initialize(name, priority, options = {})
        super
        @db_feature = options.fetch(:db_feature)
        @component = options.fetch(:component, nil)
      end

      def to_s
        @name + (@component ? " (#{@component})" : '')
      end

      def inspect
        component = @component ? ':' + @component : ''
        "#{self.class.name.split('::').last}(#{@name}#{component} [#{@priority}])"
      end

      def status
        db_status
      end

      def disable
        [0, db_status("It can't be disabled.").last]
      end

      def enable
        [0, db_status("It can't be enabled.").last]
      end

      def start
        db_status
      end

      def stop
        [0, db_status.last]
      end

      def running?
        status.first == 0
      end

      def matches?(service)
        if service.instance_of?(self.class)
          service.name == @name && service.component == @component
        elsif service.is_a? String
          service == @name
        else
          false
        end
      end

      def exist?
        true
      end

      private

      def db_status(msg = nil)
        msg = " #{msg}" if msg
        if @db_feature.ping
          [0, "#{self} is remote and is UP.#{msg}"]
        elsif @db_feature.psql_cmd_available?
          [1, "#{self} is remote and is DOWN.#{msg}" \
          "\nUnable to connect to the remote database." \
          "\nSee the log " \
          "(#{ForemanMaintain.config.log_filename}) for more details.#{msg}"]
        else
          [1, 'The psql command not found.'\
          "\nMake sure system has psql utility installed."]
        end
      end
    end
  end
end
