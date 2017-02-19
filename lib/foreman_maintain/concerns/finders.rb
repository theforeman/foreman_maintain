module ForemanMaintain
  module Concerns
    module Finders
      def detector
        @detector ||= ForemanMaintain.detector
      end

      def feature(label)
        detector.feature(label)
      end

      def check(label)
        ensure_one_object(:check, label)
      end

      def find_checks(conditions)
        detector.available_checks(conditions)
      end

      def procedure(label)
        ensure_one_object(:procedure, label)
      end

      def find_procedures(conditions)
        detector.available_procedures(conditions)
      end

      def find_scenarios(conditions)
        detector.available_scenarios(conditions)
      end

      private

      def ensure_one_object(object_type, label_or_class)
        objects = find_objects(object_type, label_or_class)
        if objects.first.nil?
          raise "#{object_type} #{label_or_class} not present"
        elsif objects.size > 1
          raise "Multiple objects of #{object_type} found for #{label_or_class}"
        else
          objects.first
        end
      end

      def label_or_class_condition(label_or_class)
        case label_or_class
        when Symbol
          { :label => label_or_class }
        when Class
          { :class => label_or_class }
        else
          raise 'Expecting symbol or class'
        end
      end

      def find_objects(object_type, label_or_class)
        conditions = label_or_class_condition(label_or_class)
        case object_type
        when :procedure
          detector.available_procedures(conditions)
        when :check
          detector.available_checks(conditions)
        else
          raise "Unexpected object type #{object_type}"
        end
      end
    end
  end
end
