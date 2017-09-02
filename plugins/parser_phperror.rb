# vim: ts=2
#
require 'fluent/parser'

module Fluent
  class TextParser
    class PhpErrorParser < Parser
      Plugin.register_parser('phperror', self)

      config_param :xdebug, :bool, :default => false
      
      REGEXP = /\[([^ ]*) ([^ ]*) .+?\] PHP ([^\:]+)\:\s+(.+)/im
      XDEBUG_REGEXP = /\[.+\] PHP (.+)/i
      FATAL_REGEXP = /\[.+\] PHP Fatal error\:\s+.+/i
      THROWN_REGEXP = /^\s+thrown in (.+) on/i
      LAST_XDEBUG_REGEXP = /\[.+\] PHP End stack trace/i
      CAUSE_REGEXP = /(.+ in (.+) on line (\d+)) /i
      CAUSE_REGEXP2 = /(.+ in (.+) on line (\d+))/i 
      
      def initialize
        super
        @error = []
        @is_trace = false
        @thrown = false
      end

      def configure(conf)
        super
      end

      def parse(text, &block) 
        if parse_internal(text)
          begin
            match = REGEXP.match(@error.join("\n"))

            if match
              time = Time.strptime(match[1] + ' ' + match[2], '%d-%b-%Y %H:%M:%S').to_i
              record = {
                :level => match[3],
                :full_message => match[4]
              }

              cause = @thrown ? @error.last : record[:full_message]
              cause_match = CAUSE_REGEXP.match(cause)

              if not cause_match
                cause_match = CAUSE_REGEXP2.match(cause)
              end

              if cause_match
                record['short_message'] = @thrown ? record[:full_message].lines.first : cause_match[1]
                record[:file] = cause_match[2]
                record[:line] = cause_match[3]
              end

              if block
                yield time, record
                return
              else
                return time, record
              end
            end
          ensure
            @error = []
            @is_trace = false
            @thrown = false
          end
        end
      end

      def parse_internal(text)
        if not @is_trace
          if is_stacktrace?(text)
            @error << text
            @is_trace = true
            return false
          elsif REGEXP.match(text)
            @error << text
            return true
          end
        end

        m = XDEBUG_REGEXP.match(text)
        if m 
          @error << m[1]
        else
          @error << text
        end

        if is_endtrace?(text)
          return true
        end
      end

      def is_stacktrace?(text) 
        return !!FATAL_REGEXP.match(text) || (!!REGEXP.match(text) && @xdebug)
      end

      def is_endtrace?(text)
        @thrown = !!THROWN_REGEXP.match(text)
        @thrown || (@xdebug && !!LAST_XDEBUG_REGEXP.match(text))
      end
    end
  end
end
