module Dragonfly
  class CookieMonster

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers.delete('Set-Cookie') if env['dragonfly.job']
      [status, headers, body]
    end

  end
end
