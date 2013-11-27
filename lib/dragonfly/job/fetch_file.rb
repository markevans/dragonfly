require 'pathname'
require 'dragonfly/job/step'

module Dragonfly
  class Job
    class FetchFile < Step
      def initialize(job, path)
        super(job, path.to_s)
      end
      def init
        job.url_attributes.name = filename
      end

      def path
        @path ||= File.expand_path(args.first)
      end

      def filename
        @filename ||= File.basename(path)
      end

      def apply
        job.content.update(Pathname.new(path), 'name' => filename)
      end
    end
  end
end
