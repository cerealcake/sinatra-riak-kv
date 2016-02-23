APP_ROOT = "#{File.dirname(__FILE__)}/../"

require 'rubygems'
require 'bundler/setup'

require "settings"

# sinatra stuff
require "sinatra/base"
require "sinatra/partial"
require "sinatra/namespace"

# miscellaneous stuff
require "highline"
require "json"

# our own helpers
require "application_helpers"
require "session_helpers"

# specific to this app
require "socket"
require 'net/http'

# authentication
require 'net/ldap'
require 'rubycas-client'

require "date"
require "redis"
require 'riak'
require 'tilt/haml'

class  ApplicationController < Sinatra::Base
  register Sinatra::Partial
  register Sinatra::Namespace

  enable :sessions
  set :sessions, :expire_after => 2592000
  enable :partial_underscores

  helpers ApplicationHelpers
  helpers SessionHelpers

  set :root, APP_ROOT
  set :views, Proc.new { File.join(root, "views") }
  set :public_folder, Proc.new { File.join(root, "public") }
  set :env,     :production
  set :port, SETTINGS.port if SETTINGS.port

  error Sinatra::NotFound do
    '404'.to_json
  end

end
