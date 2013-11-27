require 'dragonfly/job/step'

module Dragonfly
  class Job
    class Process < Step
      def init
        processor.update_url(job.url_attributes, *arguments) if processor.respond_to?(:update_url)
      end

      def name
        args.first.to_sym
      end

      def arguments
        args[1..-1]
      end

      def processor
        @processor ||= app.get_processor(name)
      end

      def apply
        processor.call(job.content, *arguments)
      end
    end
  end
end
