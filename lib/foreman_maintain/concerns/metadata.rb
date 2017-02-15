module ForemanMaintain
  module Concerns
    module Metadata
      module DSL
        def label(label)
          metadata[:label] = label
        end

        def tags(*tags)
          metadata[:tags].concat(tags)
        end

        def description(description)
          metadata[:description] = description
        end

        def confine(&block)
          metadata[:confine_blocks] << block
        end

        # Mark the class as autodetect: this means the instance
        # of class will be initialized by detector and the confine block
        # will be used to determine if it's valid on the system or not.
        # The classes not marked as autodetect need to be initialized
        # in from other places (such as `additional_features` in Feature)
        def autodetect
          @autodetect = autodetect_default
        end

        def autodetect?
          @autodetect
        end

        def autodetect_default
          true
        end

        # Specify what feature the definition related to.
        def for_feature(feature_label)
          metadata[:for_feature] = feature_label
          confine do
            feature(feature_label)
          end
        end
      end

      module ClassMethods
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

        def all_sub_classes(ignore_abstract_classes = true)
          ret = []
          ret << self if !ignore_abstract_classes || !abstract_class
          sub_classes.each do |sub_class|
            ret.concat(sub_class.all_sub_classes(ignore_abstract_classes))
          end
          ret
        end

        def metadata
          @metadata ||= initialize_metadata
        end

        def initialize_metadata
          { :tags => [],
            :confine_blocks => [] }.tap do |metadata|
            if superclass.respond_to?(:metadata)
              metadata[:label] = superclass.metadata[:label]
            end
          end
        end
      end

      def self.included(klass)
        klass.extend(DSL)
        klass.extend(ClassMethods)
      end

      def metadata
        self.class.metadata
      end

      def description
        metadata[:description] || to_s
      end

      def tags
        metadata[:tags]
      end

      def present?
        @_present ||= evaluate_confines
      end

      private

      def evaluate_confines
        raise 'Recursive dependency in confine blocks detected' if @confines_evaluation_in_progress
        @confines_evaluation_in_progress = true
        metadata[:confine_blocks].all? do |block|
          instance_exec(&block)
        end
      ensure
        @confines_evaluation_in_progress = false
      end
    end
  end
end
