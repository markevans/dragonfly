module Dragonfly
  class Job
    class Step

      class << self
        # Dragonfly::Job::Fetch -> 'Fetch'
        def basename
          @basename ||= name.split('::').last
        end
        # Dragonfly::Job::Fetch -> :fetch
        def step_name
          @step_name ||= basename.gsub(/[A-Z]/){ "_#{$&.downcase}" }.sub('_','').to_sym
        end
        # Dragonfly::Job::Fetch -> 'f'
        def abbreviation
          @abbreviation ||= basename.scan(/[A-Z]/).join.downcase
        end
      end

      def initialize(job, *args)
        @job, @args = job, args
        init
      end

      def init # To be overridden
      end

      attr_reader :job, :args

      def app
        job.app
      end

      def to_a
        [self.class.abbreviation, *args]
      end

      def inspect
        "#{self.class.step_name}(#{args.map{|a| a.inspect }.join(', ')})"
      end

    end
  end
end
