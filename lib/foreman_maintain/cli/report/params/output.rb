module ForemanMaintain
  module Cli
    module Report
      module Params
        class Output
          attr_reader :output

          def initialize(output = nil)
            @output = output.to_s.downcase
          end

          def validate!
            present!
            validate_args!
            validate_format!
          end

          def to_params
            output
          end

          private

          def present!
            raise ArgumentError, 'value not specified' if output.blank?
          end

          def validate_args!
            raise ArgumentError, 'too many arguments' if too_many_args?
          end

          def validate_format!
            raise ArgumentError, 'invalid format' unless valid_format?
          end

          def too_many_args?
            output.split(',').map(&:strip).length > 1
          end

          def valid_format?
            %w[json plain-text yaml].include?(output)
          end
        end
      end
    end
  end
end
