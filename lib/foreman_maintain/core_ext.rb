module ForemanMaintain
  module CoreExt
    module StripHeredoc
      def strip_heredoc
        indent = 0
        indented_lines = scan(/^[ \t]+(?=\S)/)
        unless indented_lines.empty?
          indent = indented_lines.min.size
        end
        gsub(/^[ \t]{#{indent}}/, '')
      end
    end
    String.send(:include, StripHeredoc)

    module StringSymbolUtils
      def camel_case
        return self if self !~ /_/ && self =~ /[A-Z]+.*/
        split('_').map(&:capitalize).join
      end

      def dashize
        to_s.tr('_', '-')
      end

      def underscorize
        to_s.tr('-', '_')
      end
    end
    String.send(:include, StringSymbolUtils)
    Symbol.send(:include, StringSymbolUtils)

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

    module FriendlyByte
      CONVERSION_NORMS = {
        :k => 1024,
        :m => 1024**2,
        :g => 1024**3,
        :t => 1024**4
      }.freeze

      def to_bytes(metric)
        to_i * CONVERSION_NORMS[metric.to_sym]
      end
    end
    Numeric.send(:include, FriendlyByte)
    String.send(:include, FriendlyByte)

    module ObjectFunctions
      def blank?
        respond_to?(:empty?) ? empty? : !self
      end
    end
    Object.send(:include, ObjectFunctions)
  end
end
