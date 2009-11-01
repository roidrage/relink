require 'redis'

$redis = Redis.new

class RedisUrl
  attr_accessor :url, :id
  
  def initialize(url = nil)
    @url = url
  end

  def self.find(id)
    u = $redis.get(key(id))
    redis_url = RedisUrl.new(u)
    redis_url.id = id
    redis_url
  end
  
  def self.find_by_url(url)
    u = $redis.get(reverse_key(url))
    if u
      redis_url = RedisUrl.new(url)
      redis_url.id = u
      redis_url
    end
  end
  
  def self.find_or_create(url)
    find_by_url(url) || create(url)
  end
  
  def self.key(id)
    "red.is.url|#{id}"
  end

  def self.create(url)
    new(url).save
  end
  
  def key
    self.class.key(@id)
  end
  
  def clicked_key
    "red.is.url.clicks|#{id}"
  end
  
  def clicked
    $redis.setnx(clicked_key, '0')
    $redis.incr(clicked_key)
  end
  
  def self.reverse_key(url)
    "red.is.url.reverse|#{url}"
  end
  
  def reverse_key
    self.class.reverse_key(@url)
  end
  
  def save
    set_id
    $redis.set(key, @url)
    $redis.set(reverse_key, @id)
    self
  end
  
  def seed
    salt = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".split('')
    secret = ''
    1.upto(4) do
      secret += salt[(rand * salt.length).floor]
    end
    secret
  end
  
  def counter
    'red.is.seeder'
  end
  
  def set_id
    @id = seed
  end
end