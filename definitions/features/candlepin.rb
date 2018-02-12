class Features::Candlepin < ForemanMaintain::Feature
  metadata do
    label :candlepin

    confine do
      find_package('candlepin')
    end
  end

  def services
    {
      'tomcat' => 20,
      'tomcat6' => 20
    }
  end
end
