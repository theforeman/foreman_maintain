module ForemanMaintain
  module Utils
    class Response
      attr_reader :data, :message
      def initialize(success, message, data: {})
        @success = success
        @message = message
        @data = data
      end

      def success?
        !!@success
      end
    end
  end
end
