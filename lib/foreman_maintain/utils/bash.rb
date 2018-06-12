require 'yaml'

module ForemanMaintain
  module Utils
    module Bash
      class Completion
        def initialize(dict)
          @dict = dict
        end

        def complete(line)
          @complete_line = line.end_with?(' ')
          full_path = line.split(' ')
          complete_path = @complete_line ? full_path : full_path[0..-2]
          dict, path = traverse_tree(@dict, complete_path)

          return [] unless path.empty? # lost during traversing

          if @complete_line
            next_word(dict)
          else
            finish_word(dict, full_path.last)
          end
        end

        def self.load_description(path)
          begin
            description = YAML.load(File.open(path))
          rescue Errno::ENOENT
            description = {}
          end
          description
        end

        private

        def finish_word(dict, incomplete)
          finish_option_value(dict, incomplete) ||
            (finish_option_or_subcommand(dict, incomplete) + finish_params(dict, incomplete))
        end

        def finish_params(dict, incomplete)
          if dict.key?(:params)
            if dict[:params].first.key?(:directory)
              directories(incomplete)
            elsif dict[:params].first.key?(:file)
              files(incomplete, dict[:params].first[:file])
            else
              []
            end
          else
            []
          end
        end

        def finish_option_or_subcommand(dict, incomplete)
          dict.keys.select { |k| k.is_a?(String) && k =~ /^#{incomplete}/ }
        end

        def finish_option_value(dict, incomplete)
          if dict.key?(:directory)
            directories(incomplete)
          elsif dict.key?(:file)
            files(incomplete, dict[:file])
          end
        end

        def next_word(dict)
          next_option_value(dict) || (next_option_or_subcommand(dict) + next_param(dict))
        end

        def next_param(dict)
          if dict.key?(:params)
            if dict[:params].first.key?(:directory)
              directories
            elsif dict[:params].first.key?(:file)
              files('', dict[:params].first[:file])
            elsif dict[:params].first.key?(:value)
              ['--->', 'Add parameter']
            end
          else
            []
          end
        end

        def next_option_or_subcommand(dict)
          dict.keys.select { |k| k.is_a?(String) }
        end

        def next_option_value(dict)
          if dict.key?(:value)
            ['--->', 'Add option <value>']
          elsif dict.key?(:directory)
            directories
          elsif dict.key?(:file)
            files('', dict[:file])
          end
        end

        def traverse_tree(dict, path)
          return [dict, []] if path.nil? || path.empty?
          result = if dict.key?(path.first)
                     if path.first.start_with?('-')
                       parse_option(dict, path)
                     else
                       parse_subcommand(dict, path)
                     end
                   elsif dict[:params]
                     # traverse params one by one
                     parse_params(dict, path)
                   else
                     # not found
                     [{}, path]
                   end
          result
        end

        def parse_params(dict, path)
          traverse_tree({ :params => dict[:params][1..-1] }, path[1..-1])
        end

        def parse_subcommand(dict, path)
          traverse_tree(dict[path.first], path[1..-1])
        end

        def parse_option(dict, path)
          if dict[path.first].empty? # flag
            traverse_tree(dict, path[1..-1])
          elsif path.length >= 2 # option with value
            traverse_tree(dict, path[2..-1])
          else
            [dict[path.first], path[1..-1]]
          end
        end

        def directories(partial = '')
          dirs = []
          dirs += Dir.glob("#{partial}*").select { |f| File.directory?(f) }
          dirs += dirs.map { |d| d + '/' } if dirs.length == 1
          dirs
        end

        def files(partial = '', opts = {})
          filter = opts.fetch(:filter, '.*')
          file_names = []
          file_names += Dir.glob("#{partial}*").select do |f|
            File.directory?(f) || f =~ /#{filter}/
          end
          file_names.map { |f| File.directory?(f) ? f + '/' : f }
        end
      end
    end
  end
end
