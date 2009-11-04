require "sinatra/authorization"
require 'digest/sha1'

set :authorization_realm, "Protected zone"

helpers do
  include Sinatra::Authorization
  
  def authorization_realm
    options.authorization_realm
  end

  def authorize(user, password)
    if $credentials
      user && password && $credentials[user] == Digest::SHA1.hexdigest(password)
    else
      true
    end
  end
  
  def authorized?
    $credentials.nil? || session[:user] || super
  end
  
  def login_required
    return if authorized?
    unauthorized! unless auth.provided?
    bad_request!  unless auth.basic?
    unauthorized! unless authorize(*auth.credentials)
    request.env['REMOTE_USER'] = auth.username
    session[:user] = auth.username
  end


  # Name provided by the current user to log in
  def current_user
    request.env['REMOTE_USER'] || session[:user]
  end
  
end

auth_file = File.dirname(__FILE__) + "/htpasswd"

if File.exists?(auth_file)
  $credentials = {}
  File.open(auth_file, "r") do |f|
    f.readlines.each do |line|
      user, password = line.split(":")
      $credentials[user] = password.chomp
    end
  end
end

