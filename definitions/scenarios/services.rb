module ForemanMaintain::Scenarios
  class ServiceRestart < ForemanMaintain::Scenario
    metadata do
      description 'Restart Services'
      tags :service_restart
      label :service_restart
      manual_detection
    end

    def compose
      add_step(Checks::RootUser)
      add_steps_with_context(Procedures::Service::Restart)
    end

    def set_context_mapping
      context.map(:only,
        Procedures::Service::Restart => :only)

      context.map(:exclude,
        Procedures::Service::Restart => :exclude)

      context.map(:wait_for_server_response,
        Procedures::Service::Restart => :wait_for_server_response)
    end
  end

  class ServiceStop < ForemanMaintain::Scenario
    metadata do
      description 'Stop Services'
      tags :service_stop
      label :service_stop
      manual_detection
    end

    def compose
      add_step(Checks::RootUser)
      add_steps_with_context(Procedures::Service::Stop)
    end

    def set_context_mapping
      context.map(:only,
        Procedures::Service::Stop => :only)

      context.map(:exclude,
        Procedures::Service::Stop => :exclude)
    end
  end

  class ServiceStart < ForemanMaintain::Scenario
    metadata do
      description 'Start Services'
      tags :service_start
      label :service_start
      manual_detection
    end

    def compose
      add_step(Checks::RootUser)
      add_steps_with_context(Procedures::Service::Start)
    end

    def set_context_mapping
      context.map(:only,
        Procedures::Service::Start => :only)

      context.map(:exclude,
        Procedures::Service::Start => :exclude)
    end
  end

  class ServiceList < ForemanMaintain::Scenario
    metadata do
      description 'Service List'
      tags :services_list
      label :services_list
      manual_detection
    end

    def compose
      add_steps_with_context(Procedures::Service::List)
    end

    def set_context_mapping
      context.map(:only,
        Procedures::Service::List => :only)

      context.map(:exclude,
        Procedures::Service::List => :exclude)
    end
  end

  class ServiceEnable < ForemanMaintain::Scenario
    metadata do
      description 'Enable Services'
      tags :service_enable
      label :service_enable
      manual_detection
    end

    def compose
      add_step(Checks::RootUser)
      add_steps_with_context(Procedures::Service::Enable)
    end

    def set_context_mapping
      context.map(:only,
        Procedures::Service::Enable => :only)

      context.map(:exclude,
        Procedures::Service::Enable => :exclude)
    end
  end

  class ServiceDisable < ForemanMaintain::Scenario
    metadata do
      description 'Disable Services'
      tags :service_disable
      label :service_disable
      manual_detection
    end

    def compose
      add_step(Checks::RootUser)
      add_steps_with_context(Procedures::Service::Disable)
    end

    def set_context_mapping
      context.map(:only,
        Procedures::Service::Disable => :only)

      context.map(:exclude,
        Procedures::Service::Disable => :exclude)
    end
  end

  class ServiceStatus < ForemanMaintain::Scenario
    metadata do
      description 'Status Services'
      tags :service_status
      label :service_status
      manual_detection
    end

    def compose
      add_steps_with_context(Procedures::Service::Status)
    end

    def set_context_mapping
      context.map(:only,
        Procedures::Service::Status => :only)

      context.map(:exclude,
        Procedures::Service::Status => :exclude)

      context.map(:brief,
        Procedures::Service::Status => :brief)

      context.map(:failing,
        Procedures::Service::Status => :failing)
    end
  end
end
