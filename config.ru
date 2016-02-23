$LOAD_PATH.unshift *Dir["#{File.dirname(__FILE__)}/lib/"]
require "application_controller"

Dir.glob('./{models,helpers,controllers}/*.rb').each { |file| require file }

maps = {
  '/api/v1/auth' => AuthController,
  '/api/v1/riak' => RiakController,
}

maps.each do |path, controller|
  map(path){ run controller}
end
