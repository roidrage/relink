$:.<<(File.dirname(__FILE__) + "/../")
require 'rubygems'
require 'sinatra'
require 'red-is'
require 'test/unit'
require 'rack/test'

set :environment, :test

class RedisTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end