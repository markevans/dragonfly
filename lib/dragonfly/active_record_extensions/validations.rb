module Dragonfly
  module ActiveRecordExtensions
    module Validations
      
      def validates_mime_type_of(*args)
        opts = args.last
        raise ArgumentError, "you must provide either :in => [(mime-types)] or :as => '(mime-type)' to validates_mime_type_of" unless opts.is_a?(::Hash) &&
          (allowed_mime_types = opts[:in] || [opts[:as]])
        validates_each(*args) do |record, attr, attachment|
          if attachment
            mime_type = attachment.temp_object.mime_type
            record.errors.add attr, "doesn't have the correct MIME-type. It needs to be #{'one of ' if allowed_mime_types.length > 1}'#{allowed_mime_types.join('\', \'')}', but was '#{mime_type || 'unknown'}'" unless allowed_mime_types.include?(mime_type)
          end
        end
      end

    end
  end
end