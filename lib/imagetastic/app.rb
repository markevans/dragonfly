module Imagetastic
  class App
    def call(env)
      [200, {"Content-Type" => "text/html"}, "This is imagetastic!"]
    end
  end
end