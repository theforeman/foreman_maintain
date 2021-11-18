class Features::Candlepin < ForemanMaintain::Feature
  metadata do
    label :candlepin

    confine do
      find_package('candlepin')
    end
  end

  def work_dir
    '/var/lib/candlepin'
  end

  def services
    [
      system_service('tomcat', 20)
    ]
  end
end
