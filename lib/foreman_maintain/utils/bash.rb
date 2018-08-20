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

          partial = @complete_line ? '' : full_path.last
          finish_word(dict, partial)
        end

        def self.load_description(path)
          YAML.load(File.open(path))
        rescue Errno::ENOENT
          {}
        end

        private

        def finish_word(dict, incomplete)
          finish_option_value(dict, incomplete) ||
            (finish_option_or_subcommand(dict, incomplete) + finish_param(dict, incomplete))
        end

        def finish_option_or_subcommand(dict, incomplete)
          dict.keys.select { |k| k.is_a?(String) && k =~ /^#{incomplete}/ }.map { |k| k + ' ' }
        end

        def complete_value(value_description, partial, is_param)
          case value_description[:type]
          when :value
            if !partial.empty?
              []
            elsif is_param
              ['--->', 'Add parameter']
            else
              ['--->', 'Add option <value>']
            end
          when :directory
            directories(partial)
          when :file
            files(partial, value_description)
          end
        end

        def finish_param(dict, incomplete)
          if dict[:params] && !dict[:params].empty?
            complete_value(dict[:params].first, incomplete, true)
          else
            []
          end
        end

        def finish_option_value(dict, incomplete)
          complete_value(dict, incomplete, false) if dict.key?(:type)
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
          if dict[path.first][:type] == :flag # flag
            traverse_tree(dict, path[1..-1])
          elsif path.length >= 2 # option with value
            traverse_tree(dict, path[2..-1])
          else # option with value missing
            [dict[path.first], path[1..-1]]
          end
        end

        def directories(partial = '')
          dirs = []
          dirs += Dir.glob("#{partial}*").select { |f| File.directory?(f) }
          dirs = dirs.map { |d| d + '/' } if dirs.length == 1
          dirs
        end

        def files(partial = '', opts = {})
          filter = opts.fetch(:filter, '.*')
          file_names = []
          file_names += Dir.glob("#{partial}*").select do |f|
            File.directory?(f) || f =~ /#{filter}/
          end
          file_names.map { |f| File.directory?(f) ? f + '/' : f + ' ' }
        end
      end
    end
  end
end
