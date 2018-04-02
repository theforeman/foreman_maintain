require 'foreman_maintain/csv_parser'

module ForemanMaintain
  module Cli
    class Base < Clamp::Command
      include Concerns::Finders

      attr_reader :runner

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
        @reporter ||= Reporter::CLIReporter.new(STDOUT,
                                                STDIN,
                                                :assumeyes => option_wrapper('assumeyes?'))
      end

      def run_scenario(scenarios)
        @runner ||=
          ForemanMaintain::Runner.new(reporter, scenarios,
                                      :assumeyes => option_wrapper('assumeyes?'),
                                      :whitelist => option_wrapper('whitelist') || [],
                                      :force => option_wrapper('force?'))
        runner.run
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

      def self.option(switches, type, description, opts = {}, &block)
        multivalued = opts.delete(:multivalued)
        description += ' (comma-separated list)' if multivalued
        super(switches, type, description, opts) do |value|
          value = CSVParser.new.parse(value) if multivalued
          value = instance_exec(value, &block) if block
          value
        end
      end

      def self.label_option
        option '--label', 'label',
               'Limit only for a specific label. ' \
                 '(Use "list" command to see available labels)' do |label|
          raise ArgumentError, 'value not specified' if label.nil? || label.empty?
          underscorize(label).to_sym
        end
      end

      def self.tags_option
        option('--tags', 'tags',
               'Limit only for specific set of labels. ' \
                 '(Use list-tags command to see available tags)',
               :multivalued => true) do |tags|
          raise ArgumentError, 'value not specified' if tags.nil? || tags.empty?
          tags.map { |tag| underscorize(tag).to_sym }
        end
      end

      def self.interactive_option
        delete_duplicate_assumeyes_if_any

        option ['-y', '--assumeyes'], :flag,
               'Automatically answer yes for all questions'

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
