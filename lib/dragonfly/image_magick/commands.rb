module Dragonfly
  module ImageMagick
    module Commands
      module_function

      def convert(content, args = "", opts = {})
        convert_command = content.env[:convert_command] || "convert"
        format = opts["format"]

        input_args = opts["input_args"] if opts["input_args"]
        delegate_string = "#{opts["delegate"]}:" if opts["delegate"]
        frame_string = "[#{opts["frame"]}]" if opts["frame"]

        content.shell_update :ext => format do |old_path, new_path|
          "#{convert_command} -auto-orient #{input_args} #{delegate_string}#{old_path}#{frame_string} #{args} #{new_path}"
        end

        if format
          content.meta["format"] = format.to_s
          content.ext = format
          content.meta["mime_type"] = nil # don't need it as we have ext now
        end
      end

      def generate(content, args, format)
        format = format.to_s
        convert_command = content.env[:convert_command] || "convert"
        content.shell_generate :ext => format do |path|
          "#{convert_command} #{args} #{path}"
        end
        content.add_meta("format" => format)
      end
    end
  end
end
