require 'foreman_maintain/csv_parser'

module ForemanMaintain
  module Cli
    class Base < Clamp::Command
      include Concerns::Finders

      attr_reader :runner

      def label_string(string)
        HighLine.color("[#{string.dashize}]", :yellow)
      end

      def tag_string(string)
        HighLine.color("[#{string.dashize}]", :cyan)
      end

      def print_check_info(check)
        desc = "#{label_string(check.label)} #{check.description}".ljust(80)
        tags = check.tags.map { |t| tag_string(t) }.join(' ').to_s
        puts "#{desc} #{tags}".strip
      end

      def reporter
        @reporter ||= ForemanMaintain::Reporter::CLIReporter.new(STDOUT,
                                                                 STDIN,
                                                                 :assumeyes => assumeyes?)
      end

      def run_scenario(scenarios)
        @runner ||=
          ForemanMaintain::Runner.new(reporter, scenarios,
                                      :assumeyes => assumeyes?,
                                      :whitelist => whitelist || [],
                                      :force => force?)
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
          raise ArgumentError, 'value not specified' if label.blank?
          label.underscorize.to_sym
        end
      end

      def self.tags_option
        option('--tags', 'tags',
               'Limit only for specific set of labels. ' \
                 '(Use list-tags command to see available tags)',
               :multivalued => true) do |tags|
          raise ArgumentError, 'value not specified' if tags.blank?
          tags.map(&:strip).map { |tag| tag.underscorize.to_sym }
        end
      end

      def self.interactive_option
        delete_duplicate_assumeyes_if_any

        option ['-y', '--assumeyes'], :flag,
               'Automatically answer yes for all questions'

        option(['-w', '--whitelist'], 'whitelist',
               'Comma-separated list of labels of steps to be ignored') do |whitelist|
          raise ArgumentError, 'value not specified' if whitelist.nil? || whitelist.empty?
          whitelist.split(',').map(&:strip)
        end

        option ['-f', '--force'], :flag,
               'Force steps that would be skipped as they were already run'
      end

      def self.delete_duplicate_assumeyes_if_any
        declared_options.delete_if { |opt| opt.handles?('--assumeyes') }
      end
    end
  end
end
