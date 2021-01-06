module ForemanMaintain::Utils
  module Service
    class Abstract
      include Comparable
      attr_reader :name, :priority

      def initialize(name, priority, options = {})
        @name = name
        @priority = priority
        @options = options
      end

      def socket
        if @options[:socket]
          self.class.new("#{@options[:socket]}.socket", priority)
        end
      end

      def <=>(other)
        prio_cmp = @priority <=> other.priority
        prio_cmp == 0 ? @name <=> other.name : prio_cmp
      end

      def to_s
        @name
      end

      def inspect
        "#{self.class.name.split('::').last}(#{@name} [#{@priority}])"
      end

      def matches?(service)
        if service.is_a? String
          service == @name
        elsif service.instance_of?(self.class)
          service.name == @name
        else
          false
        end
      end

      def exist?
        raise NotImplementedError
      end

      def status
        raise NotImplementedError
      end

      def start
        raise NotImplementedError
      end

      def stop
        raise NotImplementedError
      end

      def enable
        raise NotImplementedError
      end

      def disable
        raise NotImplementedError
      end

      def running?
        raise NotImplementedError
      end
    end
  end
end
