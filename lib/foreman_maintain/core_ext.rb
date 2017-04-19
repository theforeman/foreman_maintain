module ForemanMaintain
  module CoreExt
    module StripHeredoc
      def strip_heredoc
        indent = scan(/^[ \t]*(?=\S)/).min.size || 0
        gsub(/^[ \t]{#{indent}}/, '')
      end
    end
    String.send(:include, StripHeredoc)

    module ValidateOptions
      def validate_options!(*valid_keys)
        valid_keys.flatten!
        unexpected_options = keys - valid_keys - valid_keys.map(&:to_s)
        unless unexpected_options.empty?
          raise ArgumentError, "Unexpected options #{unexpected_options.inspect}. "\
            "Valid keys are: #{valid_keys.map(&:inspect).join(', ')}"
        end
        self
      end
    end
    Hash.send(:include, ValidateOptions)
  end
end
