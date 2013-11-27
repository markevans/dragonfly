require 'dragonfly/job/step'

module Dragonfly
  class Job
    class Fetch < Step
      class NotFound < RuntimeError; end

      def uid
        args.first
      end

      def apply
        content, meta = app.datastore.read(uid)
        raise NotFound, "uid #{uid} not found" if content.nil?
        job.content.update(content, meta)
      end
    end
  end
end
