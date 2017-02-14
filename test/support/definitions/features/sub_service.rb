module Features
  class SubService < ForemanMaintain::Feature
    label :sub_service

    def initialize(sub_service_name)
      @sub_serivce_name = sub_service_name
    end

    attr_reader :sub_service_name
  end
end
