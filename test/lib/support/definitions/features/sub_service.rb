module Features
  class SubService < ForemanMaintain::Feature
    metadata do
      label :sub_service
      manual_detection
    end

    def initialize(sub_service_name)
      @sub_serivce_name = sub_service_name
    end

    attr_reader :sub_service_name
  end
end
