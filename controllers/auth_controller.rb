class AuthController < ApplicationController

  helpers AuthHelpers

  before do
    params[:auth] ||= "ldap"
  end

  get '/' do
  end

  get '/login/?' do
     protected!(params[:auth],request,session)
     content_type :json
    "logged in".to_json
  end

  get '/logout/?' do
    content_type :json
    session[:ticket] = nil
    session[:access_token] = nil
    session[:cas_user] = nil
    session[:cas_ticket] = nil
    "logged out".to_json
  end

end
