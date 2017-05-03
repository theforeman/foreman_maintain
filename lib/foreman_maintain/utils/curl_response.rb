module ForemanMaintain
  module Utils
    class CurlResponse
      attr_reader :result, :http_code, :error_msg

      def initialize(response, http_code, http_error_msg)
        @result = response || ''
        @http_code = http_code
        @error_msg = generate_error_msg(http_error_msg)
      end

      private

      def generate_error_msg(msg_string)
        <<-EOF
        \n#{msg_string} #{http_code}. Response: #{result.inspect}
        EOF
      end
    end
  end
end
