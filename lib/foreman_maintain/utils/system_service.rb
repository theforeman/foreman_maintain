module ForemanMaintain::Utils
  class AbstractService
    include Comparable
    attr_reader :name, :priority

    def initialize(name, priority, _options = {})
      @name = name
      @priority = priority
    end

    def <=>(other)
      @priority <=> other.priority
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

  class SystemService < AbstractService
    def initialize(name, priority, _options = {})
      super
      @sys = SystemHelpers.new
    end

    def command(action, options = {})
      do_wait = options.fetch(:wait, true) # wait for service to start
      if do_wait && File.exist?('/usr/sbin/service-wait')
        "service-wait #{@name} #{action}"
      else
        "systemctl #{action} #{@name}"
      end
    end

    def status
      execute('status')
    end

    def start
      execute('start')
    end

    def stop
      execute('stop')
    end

    def enable
      execute('enable', :wait => false)
    end

    def disable
      execute('disable', :wait => false)
    end

    def running?
      status.first == 0
    end

    def exist?
      if @sys.systemd_installed?
        systemd = @sys.execute("systemctl is-enabled #{@name} 2>&1 | tail -1").strip
        systemd == 'enabled' || systemd == 'disabled'
      else
        File.exist?("/etc/init.d/#{service}")
      end
    end

    private

    def execute(action, options = {})
      @sys.execute_with_status(command(action, options))
    end
  end

  class RemoteDBService < AbstractService
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
      "RemoteDBService(#{@name}#{component} [#{@priority}])"
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
      if service.instance_of? RemoteDBService
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
      else
        [1, "#{self} is remote and is DOWN.#{msg}"]
      end
    end
  end

  def self.system_service(name, priority, options = {})
    db_feature = options.fetch(:db_feature, nil)
    if name =~ /^(postgresql|.*mongod)$/ && db_feature && db_feature.local? == false
      RemoteDBService.new(name, priority, options)
    else
      SystemService.new(name, priority, options)
    end
  end
end
