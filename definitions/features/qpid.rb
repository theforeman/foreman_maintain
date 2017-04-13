class Features::Qpid < ForemanMaintain::Feature
  metadata do
    label :qpid

    confine do
      execute?('rpm -qa |grep qpid-tools') & File.exist?('/etc/pki/katello/qpid_client_striped.crt')
    end
  end

  def clear_all
    queues_cleared = []
    available_qpid_queues.each do |qname|
      clear(qname)
      queues_cleared << qname
    end
    queues_cleared
  rescue => e
    logger.error e.message
    return queues_cleared
  end

  def count
    available_qpid_queues.length
  end

  private

  def available_qpid_queues
    output = qpid_config("list queue --show-property=name \
                          --show-property=autoDelete | awk '$2 ~ /False/{ print $1 }'")
    output ? output.split(' ') : []
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join('\n')
  end

  def clear(queue_name)
    qpid_config("del queue #{queue_name}  --force")
  end

  def qpid_config(sub_cmd)
    cmd = 'qpid-config --ssl-certificate=/etc/pki/katello/qpid_client_striped.crt\
           -b amqps://localhost:5671 '
    cmd += sub_cmd
    execute(cmd)
  end
end
