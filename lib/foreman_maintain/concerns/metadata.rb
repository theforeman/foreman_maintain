module ForemanMaintain
  module Concerns
    module Metadata
      class DSL
        attr_reader :data

        def initialize(data = {})
          @data = data
        end

        def label(label)
          @data[:label] = label
        end

        def tags(*tags)
          @data[:tags].concat(tags)
        end

        def description(description)
          @data[:description] = description
        end

        def confine(&block)
          @data[:confine_blocks] << block
        end

        # Mark the class as manual: this means the instance
        # of class will not be initialized by detector to check the confine block
        # to determine if it's valid on the system or not.
        # The classes marked for manual detect need to be initialized
        # in from other places (such as `additional_features` in Feature)
        def manual_detection
          @data[:autodetect] = false
        end

        # Specify what feature the definition related to.
        def for_feature(feature_label)
          @data[:for_feature] = feature_label
          confine do
            feature(feature_label)
          end
        end

        def self.eval_dsl(metadata, &block)
          new(metadata).tap do |dsl|
            dsl.instance_eval(&block)
          end.data
        end
      end

      module ClassMethods
        include Finders

        def inherited(klass)
          sub_classes << klass
        end

        # Override if the class should be used as parent class only.
        # By default, we assume the class that does't inherit from class with
        # Metadata is abstract = the base class of particular concept
        def abstract_class
          !(superclass < Metadata)
        end

        def sub_classes
          @sub_classes ||= []
        end

        def autodetect?
          metadata.fetch(:autodetect, true)
        end

        def all_sub_classes(ignore_abstract_classes = true)
          ret = []
          ret << self if !ignore_abstract_classes || !abstract_class
          sub_classes.each do |sub_class|
            ret.concat(sub_class.all_sub_classes(ignore_abstract_classes))
          end
          ret
        end

        def metadata(&block)
          @metadata ||= initialize_metadata
          if block
            DSL.eval_dsl(@metadata, &block)
          end
          @metadata
        end

        def label
          metadata[:label] || generate_label
        end

        def description
          metadata[:description] || to_s
        end

        def tags
          metadata[:tags]
        end

        def initialize_metadata
          { :tags => [],
            :confine_blocks => [] }.tap do |metadata|
            if superclass.respond_to?(:metadata)
              metadata[:label] = superclass.metadata[:label]
            end
          end
        end

        def present?
          evaluate_confines
        end

        private

        def evaluate_confines
          raise 'Recursive confine block call detected' if @confines_evaluation_in_progress
          @confines_evaluation_in_progress = true
          metadata[:confine_blocks].all? do |block|
            instance_exec(&block)
          end
        ensure
          @confines_evaluation_in_progress = false
        end

        def generate_label
          name.split('::').last.split(/(?=[A-Z])/).map(&:downcase).join('_').to_sym
        end
      end

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def metadata
        self.class.metadata
      end

      def label
        self.class.label
      end

      def description
        self.class.description
      end

      def tags
        self.class.tags
      end
    end
  end
end
