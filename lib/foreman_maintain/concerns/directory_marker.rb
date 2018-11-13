module ForemanMaintain
  module Concerns
    module DirectoryMarker
      def with_marked_directory(directory)
        mark_directory(directory)
        yield
        unmark_directory(directory)
      end

      def find_marked_directory(directory)
        find_dir_containing_file(directory, mark_name)
      end

      def mark_name
        cls = self.class.name.split('::').last.downcase
        ".#{cls}_directory_mark"
      end

      private

      def unmark_directory(directory)
        filename = mark_file_path(directory)
        File.delete(filename) if File.exist?(filename)
      end

      def mark_directory(directory)
        File.open(mark_file_path(directory), 'a') {}
      end

      def mark_file_path(directory)
        File.join(directory, mark_name)
      end
    end
  end
end
