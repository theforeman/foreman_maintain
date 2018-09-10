class Features::Gofer < ForemanMaintain::Feature
  metadata do
    label :gofer

    confine do
      find_package('gofer')
    end
  end

  def services
    [
      system_service('goferd', 30)
    ]
  end
end
