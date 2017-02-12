module ForemanMaintain
  module Concerns
    module Metadata
      module DSL
        def tags(*tags)
          metadata[:tags].concat(tags)
        end

        def requires_feature(*feature_names)
          metadata[:required_features].concat(feature_names)
        end

        def description(description)
          metadata[:description] = description
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
            :required_features => [] }
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
        metadata[:description] || self.to_s
      end
    end
  end
end
