module ForemanMaintain
  module Cli
    module Report
      module Params
        class Size
          attr_reader :size

          def initialize(size)
            @size = disintegrate_size(size)
          end

          def operator
            size[0]
          end

          def number
            size[1]
          end

          def metric
            size[2]
          end

          def validate!
            present!
            validate_attr!(:operator)
            validate_attr!(:number)
            validate_attr!(:metric)
          end

          def to_params
            [operator, number_in_bytes]
          end

          def number_in_bytes
            number.to_bytes(metric.chars.first)
          end

          private

          def present!
            raise ArgumentError, 'value not specified' if size.blank?
          end

          def validate_attr!(name)
            raise ArgumentError, "Invalid #{name}: #{send(name)}" unless send("valid_#{name}?")
          end

          def disintegrate_size(size)
            size.gsub(/[[:space:]]/, '').downcase.scan(/\d+|\D+/) if size
          end

          def valid_metric?
            %w[b k kb m mb g gb].include?(metric)
          end

          def valid_operator?
            %w[<= >= > < =].include?(operator)
          end

          def valid_number?
            number.match(/\d+|\D+/)
          end
        end
      end
    end
  end
end
