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

      def reporter
        @reporter ||= ForemanMaintain::Reporter::CLIReporter.new
      end

      def run_scenario(scenario)
        ForemanMaintain::Runner.new(reporter, scenario).run
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
          underscorize(label).to_sym
        end
      end

      def self.tags_option
        option '--tags', 'tags',
               'Limit only for specific set of labels. ' \
                 '(Use list-tags command to see available tags)' do |tags|
          tags && tags.split(',').map(&:strip).map { |tag| underscorize(tag).to_sym }
        end
      end
    end
  end
end
