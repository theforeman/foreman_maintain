module ForemanMaintain
  module Concerns
    module Systemd
      def action_noun(action)
        action_word_modified(action) + 'ing'
      end

      def action_past_tense(action)
        action_word_modified(action) + 'ed'
      end

      private

      def format_status(output, exit_code, options)
        status = ''
        if !options[:failing] || exit_code > 0
          if options[:brief]
            status += format_brief_status(exit_code)
          elsif !(output.nil? || output.empty?)
            status += "\n" + output
          end
        end
        status
      end

      def format_brief_status(exit_code)
        result = (exit_code == 0) ? reporter.status_label(:success) : reporter.status_label(:fail)
        padding = reporter.max_length - reporter.last_line.to_s.length - 30
        "#{' ' * padding} #{result}"
      end

      def allowed_action?(action)
        %w[start stop restart status enable disable].include?(action)
      end

      def action_word_modified(action)
        case action
        when 'status'
          'display'
        when 'enable', 'disable'
          action.chomp('e')
        when 'stop'
          action + 'p'
        else
          action
        end
      end
    end
  end
end
