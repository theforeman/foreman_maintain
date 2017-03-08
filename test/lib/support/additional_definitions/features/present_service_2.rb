require 'features/present_service'
class Features::PresentService2 < Features::PresentService
  metadata do
    label :my_test_feature

    confine do
      TestHelper.use_present_service_2
    end
  end
end
