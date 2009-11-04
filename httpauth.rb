require "sinatra/authorization"

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
    $credentials.nil? || super
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

