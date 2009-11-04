$:.<<(File.dirname(__FILE__) + "/../")
require 'rubygems'
require 'redis_url'
require 'test/unit'
require 'shoulda'
require 'active_support'
require 'active_support/testing/assertions'

class RedisUrlTest < Test::Unit::TestCase
  include ActiveSupport::Testing::Assertions
  context 'A Redis-based URL' do
    setup do
      $redis = Redis.new(:db => 10)
      $redis.flush_db
    end
    
    context 'when creating a URL' do
      should 'create a hashed identifier' do
        url = RedisUrl.create("http://www.heise.de")
        assert_equal 4, url.id.length
      end
      
      should 'save the object to redis' do
        url = RedisUrl.create("http://www.heise.de")
        assert_not_nil $redis.get(url.key)
      end
      
      should 'store a reverse lookup entry by url' do
        RedisUrl.create("http://www.heise.de")
        assert_not_nil $redis.get('relink.url.reverse|http://www.heise.de')
      end
      
      should 'increase the url count in the database' do
        assert_difference 'RedisUrl.count' do
          RedisUrl.create("http://www.heise.de")
        end
      end
      
      should 'append http if no protocol was specified' do
        assert_equal 'http://www.heise.de', RedisUrl.create("www.heise.de").url
      end
      
      context 'with invalid urls' do
        should 'not save the object when the url is pointing to f0rk.me or other url shorteners' do
          ['tinyurl.com/af13', 'bit.ly/af13', 'j.mp/af13', 'f0rk.me/af13', 'tr.im/af13', 'rubyurl.com/af13', 'roidi.us/af13'].each do |url|
            assert !RedisUrl.create(url)
          end
        end
      end
      
    end

    context 'when generating a seed' do
      should 'generate different seeds on subsequent runs' do
        url = RedisUrl.new("http://www.heise.de")
        assert_not_equal url.seed, url.seed
      end
    end
    
    context 'when finding a URL' do
      setup do
        @url = RedisUrl.create("http://www.heise.de")
      end
      
      should 'return the url with data' do
        url = RedisUrl.find(@url.id)
        assert_equal "http://www.heise.de", url.url
        assert_equal @url.id, url.id
      end
      
      should 'return nil if url not found' do
        url = RedisUrl.find('1234')
        assert_nil url
      end
    end
    
    context "when find_or_creating a URL" do
      setup do
        @url = RedisUrl.create("http://www.heise.de")
      end
      
      should 'return the url from redis when it already exists' do
        url = RedisUrl.find_or_create("http://www.heise.de")
        assert_equal @url.id, url.id
        assert_equal @url.url, url.url
      end
      
      should "create a new url in redis when it wasnt found" do
        assert_nil $redis.get(RedisUrl.reverse_key('http://cnn.com'))
        url = RedisUrl.find_or_create("http://cnn.com")
        assert_not_nil $redis.get(RedisUrl.reverse_key('http://cnn.com'))
      end
    end
    
    context "when tracking clicks" do
      setup do
        @url = RedisUrl.create("http://www.heise.de")
      end
      
      should 'increase the number of clicks' do
        assert_difference '$redis.get(@url.clicked_key).to_i' do
          @url.clicked
        end
      end
      
      should 'return the number of clicks' do
        @url = RedisUrl.create("http://www.heise.de")
        @url.clicked
        assert_equal "1", @url.clicks
      end
    end
    
    context "when finding all urls" do
      setup do
        @url = RedisUrl.create("http://www.heise.de")
        @url = RedisUrl.create("http://www.cnn.com")
      end
      
      should 'return all url objects' do
        urls = RedisUrl.all
        assert_equal 2, urls.size
        assert_equal "http://www.cnn.com", urls.first.url
        assert_equal "http://www.heise.de", urls.last.url
      end
    end
    
    context "when fetching the truncated version of a url" do
      should 'shorten the url to 50 characters plus some dots' do
        url = RedisUrl.create('http://jchrisa.net/drl/_design/sofa/_list/index/recent-posts?descending=true&limit=5')
        assert_equal 'http://jchrisa.net/dr...s?descending=true&limit=5', url.truncated_url
      end
      
      should 'not put dots in urls shorter than the maximum' do
        url = RedisUrl.create("http://www.heise.de")
        assert_equal 'http://www.heise.de', url.truncated_url
        url = RedisUrl.create("http://example.org")
        assert_equal 'http://example.org', url.truncated_url
      end
    end
  end
end
