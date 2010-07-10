$:.<<(File.dirname(__FILE__) + "/../")
require 'rubygems'
require 'sinatra'
require 'relink'
require 'test/unit'
require 'rack/test'
require 'active_support'
require 'active_support/testing/assertions'
require 'shoulda'

set :environment, :test
set :views, (File.dirname(__FILE__) + "/../views")

class RedisTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include ActiveSupport::Testing::Assertions

  def app
    Sinatra::Application
  end
  
  context "When redising urls" do
    setup do
      $redis = Redis.new(:db => 10)
      $redis.flushdb
    end
    
    context 'on the index page' do
      should 'render the form' do
        get '/'
        assert last_response.body.include?('<form')
      end
      
      should "not include a relink'd url" do
        get '/'
        assert !last_response.body.include?("relink'd")
      end
    end
    
    context 'when creating a url' do
      should "include the notification that the url has been relink'd" do
        post '/', {:url => "http://www.heise.de"}, {"HTTP_HOST" => 'localhost'}
        assert last_response.ok?
        url = RedisUrl.find_by_url("http://www.heise.de")
        assert last_response.body.include?("http://www.heise.de relink'd to")
        assert last_response.body.include?("http://localhost/#{url.id}")
      end
      
      should "create the url in redis" do
        post '/', {:url => "http://www.heise.de"}, {"HTTP_HOST" => 'localhost'}
        assert_not_nil RedisUrl.find_by_url("http://www.heise.de")
      end
      
      should 'not create different shortened urls for the same url' do
        url = RedisUrl.create("http://www.heise.de")
        assert_no_difference 'RedisUrl.count' do
          post '/', :url => 'http://www.heise.de'
        end
      end
      
      context 'with plain text response' do
        should 'return only the generate short url' do
          post '/t', {:url => "http://www.heise.de"}, {"HTTP_HOST" => 'localhost'}
          url = RedisUrl.find_by_url('http://www.heise.de')
          assert_equal "http://localhost/#{url.id}", last_response.body
        end
      end
    end
    
    context 'when requesting a shortened url' do
      should 'redirect to the url' do
        url = RedisUrl.create("http://www.heise.de")
        get "/#{url.id}"
        assert last_response.redirect?
        assert_equal "http://www.heise.de", last_response.location
      end
      
      should 'display an error when the url couldnt be found' do
        get '/asdfas'
        assert last_response.not_found?
        assert last_response.body.include?("The specified key didn't do anything for me. Sorry.")
      end
    end
    
    context 'when requesting the details page for a shortened url' do
      should 'include the number of clicks' do
        url = RedisUrl.create("http://www.heise.de")
        10.times {url.clicked}
        get "/p/#{url.id}", {}, {"HTTP_HOST" => 'localhost'}
        assert last_response.body.include?('http://www.heise.de')
        assert last_response.body.include?("http://localhost/#{url.id}")
        assert last_response.body.include?("10 clicks")
      end
      
      should 'display an error when the url couldnt be found' do
        get '/p/asdfas'
        assert last_response.not_found?
        assert last_response.body.include?("The specified key didn't do anything for me. Sorry.")
      end
    end
    
    context 'when listing all urls' do
      setup do
        url = RedisUrl.create("http://www.heise.de")
        10.times {url.clicked}
        url = RedisUrl.create("http://www.cnn.com")
        20.times {url.clicked}
      end
      
      should 'include the full url' do
        get '/list'
        assert last_response.body.include?('http://www.cnn.com')
        assert last_response.body.include?('10')
        assert last_response.body.include?('http://www.heise.de')
        assert last_response.body.include?('20')
      end
    end
  end
end
