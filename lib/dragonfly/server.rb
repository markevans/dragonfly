require 'forwardable'
require 'dragonfly/whitelist'
require 'dragonfly/url_mapper'
require 'dragonfly/job'
require 'dragonfly/response'
require 'dragonfly/serializer'

module Dragonfly
  class Server

    # Exceptions
    class JobNotAllowed < RuntimeError; end

    extend Forwardable
    def_delegator :url_mapper, :params_in_url

    def initialize(app)
      @app = app
      @dragonfly_url = '/dragonfly'
      self.url_format = '/:job/:name'
      @fetch_file_whitelist = Whitelist.new
      @fetch_url_whitelist = Whitelist.new
      @verify_urls = true
    end

    attr_accessor :verify_urls, :url_host, :url_path_prefix, :dragonfly_url

    attr_reader :url_format, :fetch_file_whitelist, :fetch_url_whitelist

    def add_to_fetch_file_whitelist(patterns)
      fetch_file_whitelist.push *patterns
    end

    def add_to_fetch_url_whitelist(patterns)
      fetch_url_whitelist.push *patterns
    end

    def url_format=(url_format)
      @url_format = url_format
      self.url_mapper = UrlMapper.new(url_format)
    end

    def before_serve(&block)
      self.before_serve_callback = block
    end

    def call(env)
      if dragonfly_url == env["PATH_INFO"]
        dragonfly_response
      elsif (params = url_mapper.params_for(env["PATH_INFO"], env["QUERY_STRING"])) && params['job']
        job = Job.deserialize(params['job'], app)
        validate_job!(job)
        job.validate_sha!(params['sha']) if verify_urls
        response = Response.new(job, env)
        catch(:halt) do
          if before_serve_callback && response.will_be_served?
            before_serve_callback.call(job, env)
          end
          response.to_response
        end
      else
        [404, {'Content-Type' => 'text/plain', 'X-Cascade' => 'pass'}, ['Not found']]
      end
    rescue Job::NoSHAGiven => e
      [400, {"Content-Type" => 'text/plain'}, ["You need to give a SHA parameter"]]
    rescue Job::IncorrectSHA => e
      [400, {"Content-Type" => 'text/plain'}, ["The SHA parameter you gave is incorrect"]]
    rescue JobNotAllowed => e
      Dragonfly.warn(e.message)
      [403, {"Content-Type" => 'text/plain'}, ["Forbidden"]]
    rescue Serializer::BadString, Serializer::MaliciousString, Job::InvalidArray => e
      Dragonfly.warn(e.message)
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    end

    def url_for(job, opts={})
      opts = opts.dup
      host = opts.delete(:host) || url_host
      path_prefix = opts.delete(:path_prefix) || url_path_prefix
      params = job.url_attributes.extract(url_mapper.params_in_url)
      params.merge!(stringify_keys(opts))
      params['job'] = job.serialize
      params['sha'] = job.sha if verify_urls
      url = url_mapper.url_for(params)
      "#{host}#{path_prefix}#{url}"
    end

    private

    attr_reader :app
    attr_accessor :before_serve_callback, :url_mapper

    def stringify_keys(params)
      params.inject({}) do |hash, (k, v)|
        hash[k.to_s] = v
        hash
      end
    end

    def dragonfly_response
      body = <<-DRAGONFLY
          _o|o_
  _~~---._(   )_.---~~_
 (       . \\ / .       )
  `-.~--'  |=|  '--~.-'
  _~-.~'" /|=|\\ "'~.-~_
 (      ./ |=| \\.      )
  `~~`"`   |=|   `"'ME"
           |-|
           <->
            V
      DRAGONFLY
      [200, {
        'Content-Type' => 'text/plain',
        'Content-Size' => body.bytesize.to_s
        },
        [body]
      ]
    end

    def validate_job!(job)
      if step = job.fetch_file_step
        validate_fetch_file_step!(step)
      end
      if step = job.fetch_url_step
        validate_fetch_url_step!(step)
      end
    end

    def validate_fetch_file_step!(step)
      unless fetch_file_whitelist.include?(step.path)
        raise JobNotAllowed, "fetch file #{step.path} disallowed - use fetch_file_whitelist to allow it"
      end
    end

    def validate_fetch_url_step!(step)
      unless fetch_url_whitelist.include?(step.url)
        raise JobNotAllowed, "fetch url #{step.url} disallowed - use fetch_url_whitelist to allow it"
      end
    end
  end
end

