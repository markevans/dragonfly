require 'dragonfly/job/step'

module Dragonfly
  class Job
    class Generate < Step
      def init
        generator.update_url(job.url_attributes, *arguments) if generator.respond_to?(:update_url)
      end

      def name
        args.first
      end

      def generator
        @generator ||= app.get_generator(name)
      end

      def arguments
        args[1..-1]
      end

      def apply
        generator.call(job.content, *arguments)
      end
    end
  end
end
