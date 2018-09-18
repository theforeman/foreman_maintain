module Checks
  module Foreman
    class PuppetClassDuplicates < ForemanMaintain::Check
      metadata do
        label :puppet_class_duplicates
        for_feature :foreman_database
        description 'Check for duplicate Puppet class records'
        tags :pre_upgrade
        confine do
          check_max_version('foreman', '1.20')
        end
      end

      def run
        duplicate_names = find_duplicate_names
        assert(duplicate_names.empty?, duplicate_msg(duplicate_names))
      end

      private

      def duplicate_msg(duplicate_names)
        msg = "There are #{duplicate_names.count} Puppet classes with duplicities:\n"
        classes_list = duplicate_names.reduce('') do |memo, hash|
          memo.tap { |acc| acc << "#{hash['name']} - #{hash['name_count']}\n" }
        end
        help_msg = 'Please head over to Configure -> Classes'
        help_msg << " and make sure there is only 1 Puppet class record for each name.\n"
        [msg, classes_list, help_msg].join('')
      end

      def find_duplicate_names
        feature(:foreman_database).query(duplicate_names_query)
      end

      def duplicate_names_query
        <<-SQL
          SELECT name, name_count
          FROM (
            SELECT name, count(name) AS name_count
            FROM puppetclasses
            GROUP BY name
          ) AS puppetclass_counts
          WHERE name_count > 1
        SQL
      end
    end
  end
end
