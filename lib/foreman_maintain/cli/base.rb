require 'foreman_maintain/csv_parser'

module ForemanMaintain
  module Cli
    class Base < Clamp::Command
      include Concerns::Finders

      attr_reader :runner

      class << self
        include Concerns::Logger

        def subcommand(name, description, subcommand_class = self, &block)
          add_command = true
          if subcommand_class.superclass == ForemanMaintain::Cli::Base
            sc = subcommand_class.to_s
            sc.slice!('ForemanMaintain::Cli::')
            if ForemanMaintain.config.disable_commands.include? sc
              logger.info("Disable command #{sc}")
              add_command = false
            end
          end
          super if add_command
        end
      end

      def self.dashize(string)
        string.to_s.tr('_', '-')
      end

      def dashize(string)
        self.class.dashize(string)
      end

      def underscorize(string)
        string.to_s.tr('-', '_')
      end

      def label_string(string)
        HighLine.color("[#{dashize(string)}]", :yellow)
      end

      def tag_string(string)
        HighLine.color("[#{dashize(string)}]", :cyan)
      end

      def print_check_info(check)
        desc = "#{label_string(check.label)} #{check.description}".ljust(80)
        tags = check.tags.map { |t| tag_string(t) }.join(' ').to_s
        puts "#{desc} #{tags}".strip
      end

      def reporter
        @reporter ||= ForemanMaintain.reporter
      end

      def run_scenario(scenarios, rescue_scenario = nil)
        @runner ||=
          ForemanMaintain::Runner.new(reporter, scenarios,
                                      :assumeyes => option_wrapper('assumeyes?'),
                                      :whitelist => option_wrapper('whitelist') || [],
                                      :force => option_wrapper('force?'),
                                      :rescue_scenario => rescue_scenario)
        runner.run
      end

      def run_scenarios_and_exit(scenarios, rescue_scenario: nil)
        run_scenario(scenarios, rescue_scenario)
        exit runner.exit_code
      end

      def available_checks
        filter = {}
        filter[:tags] = tags if respond_to?(:tags)
        ForemanMaintain.available_checks(filter)
      end

      def available_procedures
        filter = {}
        filter[:tags] = tags if respond_to?(:tags)
        ForemanMaintain.available_procedures(filter)
      end

      def available_tags(collection)
        self.class.available_tags(collection)
      end

      def self.available_tags(collection)
        collection.inject([]) { |array, item| array.concat(item.tags).uniq }.sort_by(&:to_s)
      end

      def self.completion_map
        completion = {}
        # collect options
        recognised_options.each do |opt|
          opt.switches.each do |switch|
            completion[switch] = completion_types.fetch(switch, {})
          end
        end
        # collect subcommands recursively
        recognised_subcommands.each do |cmd|
          completion[cmd.names.first] = cmd.subcommand_class.completion_map
        end
        # collect params
        completion[:params] = completion_types[:params] unless completion_types[:params].empty?
        completion
      end

      def self.completion_types
        @completion_types ||= { :params => [] }
      end

      def self.option(switches, type, description, opts = {}, &block)
        multivalued = opts.delete(:multivalued)
        completion_type = opts.delete(:completion)
        completion_type = { :type => :flag } if completion_type.nil? && type == :flag
        completion_type ||= { :type => :value }
        [switches].flatten(1).each { |s| completion_types[s] = completion_type }
        description += ' (comma-separated list)' if multivalued
        super(switches, type, description, opts) do |value|
          value = CSVParser.new.parse(value) if multivalued
          value = instance_exec(value, &block) if block
          value
        end
      end

      def self.parameter(name, description, opts = {}, &block)
        unless [:subcommand_name, :subcommand_arguments].include?(opts[:attribute_name])
          completion_type = opts.delete(:completion)
          completion_type ||= { :type => :value }
          completion_types[:params] << completion_type
        end
        super(name, description, opts, &block)
      end

      def self.label_option
        option '--label', 'label',
               'Run only a specific check with a label. ' \
                 '(Use "list" command to see available labels)' do |label|
          raise ArgumentError, 'value not specified' if label.nil? || label.empty?
          underscorize(label).to_sym
        end
      end

      def self.tags_option
        option('--tags', 'tags',
               'Run only those with all specific set of tags. ' \
                 '(Use list-tags command to see available tags)',
               :multivalued => true) do |tags|
          raise ArgumentError, 'value not specified' if tags.nil? || tags.empty?
          tags.map { |tag| underscorize(tag).to_sym }
        end
      end

      def self.interactive_option
        delete_duplicate_assumeyes_if_any

        option ['-y', '--assumeyes'], :flag,
               'Automatically answer yes for all questions' do |assume|
          ForemanMaintain.reporter.assumeyes = assume
        end

        option(['-w', '--whitelist'], 'whitelist',
               'Comma-separated list of labels of steps to be skipped') do |whitelist|
          raise ArgumentError, 'value not specified' if whitelist.nil? || whitelist.empty?
          whitelist.split(',').map(&:strip)
        end

        option ['-f', '--force'], :flag,
               'Force steps that would be skipped as they were already run'
      end

      def self.service_options
        option '--exclude', 'EXCLUDE', 'A comma-separated list of services to skip'
        option '--only', 'ONLY', 'A comma-separated list of services to include'
      end

      def self.delete_duplicate_assumeyes_if_any
        declared_options.delete_if { |opt| opt.handles?('--assumeyes') }
      end

      def option_wrapper(option)
        respond_to?(option.to_sym) ? send(option) : false
      end
    end
  end
end
