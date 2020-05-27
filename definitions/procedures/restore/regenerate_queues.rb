module Procedures::Restore
  class RegenerateQueues < ForemanMaintain::Procedure
    metadata do
      advanced_run false
      description 'Regenerate required activemq and qpidd queues while restoring online backup'
      confine do
        feature(:pulp2)
      end
    end

    def qpid_router_broker_port
      @qpid_router_broker_port ||= feature(:installer).
                                   answers['foreman_proxy_content']['qpid_router_broker_port']
    end

    def qpid_configs
      @qpid_configs ||= {
        'ssl_cert' => "/etc/pki/katello/certs/#{hostname}-qpid-broker.crt",
        'ssl_key' => "/etc/pki/katello/private/#{hostname}-qpid-broker.key",
        'amqps_url' => "amqps://localhost:#{qpid_router_broker_port}"
      }
    end

    def katello_events
      %w[compliance.created
         entitlement.created
         entitlement.deleted
         pool.created
         pool.deleted]
    end

    def run
      with_spinner('Resetting the queues') do |spinner|
        regenerate_activemq_queues(spinner)
        regenerate_qpidd_queues(spinner)
        spinner.update('Queues created successfully')
      end
    end

    def regenerate_activemq_queues(spinner)
      # The activemq queues(/var/lib/candlepin/activemq-artemis) regenerate on tomcat restart.
      # After stopping the tomcat here, service start is triggered from the restore scenario.
      spinner.update('Stopping tomcat service')
      feature(:candlepin).services.select(&:exist?).first.stop
      spinner.update('Recreating activemq queues')
      execute!('rm -rf /var/lib/candlepin/activemq-artemis/')
    end

    def run_qpid_command(opts)
      execute!("qpid-config --ssl-certificate #{qpid_configs['ssl_cert']} \\
                --ssl-key #{qpid_configs['ssl_key']} -b #{qpid_configs['amqps_url']} #{opts}")
    end

    def regenerate_qpidd_queues(spinner)
      feature(:service).handle_services(spinner, 'stop', :only => ['qpidd'])
      execute!('rm -rf /var/lib/qpidd/.qpidd/qls')
      spinner.update('Starting qpidd service')
      feature(:service).handle_services(spinner, 'start', :only => ['qpidd'])
      spinner.update('Service qpidd started, waiting 60 seconds to start it completely')
      sleep 60
      spinner.update('Recreating qpidd queues')
      run_qpid_command('add exchange topic event --durable')
      run_qpid_command('add queue katello_event_queue --durable')
      katello_events.each do |event|
        run_qpid_command("bind event katello_event_queue #{event}")
      end
    end
  end
end
