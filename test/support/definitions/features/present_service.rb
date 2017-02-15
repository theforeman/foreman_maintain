class Features::PresentService < ForemanMaintain::Feature
  label :present_service
  autodetect

  confine do
    0.zero?
  end
end
