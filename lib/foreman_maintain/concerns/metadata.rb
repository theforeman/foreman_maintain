module ForemanMaintain
  module Concerns
    module Metadata
      # limit of steps dependent on each other, to avoid endless recursion
      MAX_PREPARATION_STEPS_DEPTH = 20

      class << self
        # modules not to be included in autogenerated labels
        attr_accessor :top_level_modules
      end

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

        def before(*step_labels)
          raise Error::MultipleBeforeDetected, step_labels if step_labels.count > 1
          @data[:before].concat(step_labels)
        end

        def after(*step_labels)
          @data[:after].concat(step_labels)
        end

        # Parametrize the definition.
        #
        # == Arguments
        #
        #  +name+: Name (Symbol) of the attribute
        #  +description_or_options+: Description string or a Hash with options
        #  +options+: Hash with options (unless specified in +descriptions_or_options+)
        #  +&block+: block to be called when processing the data: can be used for validation
        #     and type-casing of the value: expected to return the value to be used
        #
        # == Options
        #
        #  +:description+: String describing the parameter
        #  +:required+: true if required
        #  +:flag+: param is just a true/false value: not expecting other values
        #
        def param(name, descripiton_or_options = {}, options = {}, &block)
          case descripiton_or_options
          when String
            description = descripiton_or_options
          when Hash
            options = options.merge(descripiton_or_options) if descripiton_or_options.is_a?(Hash)
          end
          @data[:params][name] = Param.new(name, description, options, &block)
        end

        # Mark the class as manual: this means the instance
        # of class will not be initialized by detector to check the confine block
        # to determine if it's valid on the system or not.
        # The classes marked for manual detect need to be initialized
        # in from other places (such as `additional_features` in Feature)
        def manual_detection
          @data[:autodetect] = false
        end

        # in the block, define one or more preparation steps needed
        # before executing this definition
        def preparation_steps(&block)
          @data[:preparation_steps_blocks] << block
        end

        # Specify what feature the definition related to.
        def for_feature(feature_label)
          @data[:for_feature] = feature_label
          confine do
            feature(feature_label)
          end
        end

        # Ensure to not run the step twice: expects the scenario to be persisted
        # between runs to work properly
        def run_once
          @data[:run_once] = true
        end

        def advanced_run(advanced_run)
          @data[:advanced_run] = advanced_run
        end

        def do_not_whitelist
          @data[:do_not_whitelist] = true
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
            metadata_class.eval_dsl(@metadata, &block)
          end
          @metadata
        end

        def metadata_class
          DSL
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

        def params
          metadata[:params] || {}
        end

        def before
          metadata[:before] || []
        end

        def after
          metadata[:after] || []
        end

        def run_once?
          metadata[:run_once]
        end

        def advanced_run?
          metadata[:advanced_run]
        end

        def initialize_metadata
          { :tags => [],
            :confine_blocks => [],
            :params => {},
            :preparation_steps_blocks => [],
            :before => [],
            :after => [],
            :advanced_run => true }.tap do |metadata|
            if superclass.respond_to?(:metadata)
              metadata[:label] = superclass.metadata[:label]
            end
          end
        end

        def present?
          evaluate_confines
        end

        def preparation_steps(recursion_depth = 0, trace = [])
          raise "Too many dependent steps #{trace}" if recursion_depth > MAX_PREPARATION_STEPS_DEPTH
          return @preparation_steps if defined?(@preparation_steps)
          preparation_steps = metadata[:preparation_steps_blocks].map do |block|
            instance_exec(&block)
          end.flatten.compact
          preparation_steps.each { |step| raise ArgumentError unless step.is_a?(Executable) }
          all_preparation_steps = []
          preparation_steps.each do |step|
            all_preparation_steps.concat(
              step.preparation_steps(recursion_depth + 1, trace + [step])
            )
            all_preparation_steps << step
          end
          @preparation_steps = all_preparation_steps
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
          label_parts = []
          name.split('::').reduce(Object) do |parent_constant, name|
            constant = parent_constant.const_get(name)
            unless Metadata.top_level_modules.include?(constant)
              # CamelCase -> camel_case
              label_parts << name.split(/(?=[A-Z])/).map(&:downcase)
            end
            constant
          end
          label_parts.join('_').to_sym
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

      def label_dashed
        label.to_s.tr('_', '-')
      end

      def description
        self.class.description
      end

      def runtime_message
        description
      end

      def tags
        self.class.tags
      end

      def params
        self.class.params
      end

      def run_once?
        self.class.run_once?
      end

      def preparation_steps(*args)
        self.class.preparation_steps(*args)
      end

      def advanced_run?
        self.class.advanced_run?
      end
    end
  end
end
