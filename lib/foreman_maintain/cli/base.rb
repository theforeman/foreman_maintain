module ForemanMaintain
  module Cli
    class Base < Clamp::Command
      include Concerns::Finders

      def dashize(string)
        string.to_s.tr('_', '-')
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
        @reporter ||= ForemanMaintain::Reporter::CLIReporter.new(STDOUT,
                                                                 STDIN,
                                                                 :assumeyes => assumeyes?)
      end

      def run_scenario(scenarios)
        ForemanMaintain::Runner.new(reporter, scenarios,
                                    :assumeyes => assumeyes?,
                                    :whitelist => whitelist || []).run
      end

      def available_checks
        filter = {}
        filter[:tags] = tags if respond_to?(:tags)
        ForemanMaintain.available_checks(filter)
      end

      def available_tags(collection)
        collection.inject([]) { |array, check| array.concat(check.tags).uniq }.sort_by(&:to_s)
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
        option '--tags', 'tags',
               'Limit only for specific set of labels. ' \
                 '(Use list-tags command to see available tags)' do |tags|
          raise ArgumentError, 'value not specified' if tags.nil? || tags.empty?
          tags.split(',').map(&:strip).map { |tag| underscorize(tag).to_sym }
        end
      end

      def self.interactive_option
        option ['-y', '--assumeyes'], :flag,
               'Automatically answer yes for all questions'

        option ['-w', '--whitelist'], :whitelist,
               'Comma-separated list of labels of steps to be ignored' do |whitelist|
          raise ArgumentError, 'value not specified' if whitelist.nil? || whitelist.empty?
          whitelist.split(',').map(&:strip)
        end
      end
    end
  end
end
