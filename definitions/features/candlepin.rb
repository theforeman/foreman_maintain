class Features::Candlepin < ForemanMaintain::Feature
  metadata do
    label :candlepin

    confine do
      find_package('candlepin')
    end
  end

  def services
    [
      system_service('tomcat', 20),
      system_service('tomcat6', 20)
    ]
  end
end
