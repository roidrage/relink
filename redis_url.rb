require 'redis'

$redis = Redis.new

class RedisUrl
  attr_accessor :url, :id
  
  def initialize(url = nil)
    url = "http://#{url}" unless url.match(/^https?:\/\//)
    @url = url
  end

  def self.find(id)
    u = $redis.get(key(id))
    if u
      redis_url = RedisUrl.new(u)
      redis_url.id = id
      redis_url
    end
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
  
  def self.count
    $redis.llen(all_urls)
  end
  
  def self.all
    $redis.lrange(all_urls, 0, count).collect do |url|
      find(url)
    end
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
  
  def clicks
    $redis.get(clicked_key)
  end
  
  def self.reverse_key(url)
    "red.is.url.reverse|#{url}"
  end
  
  def reverse_key
    self.class.reverse_key(@url)
  end
  
  def truncated_url
    url.length > 45 ? "#{url[0..20]}...#{url[-25..url.length]}" : url
  end
  
  def self.all_urls
    'red.is.urls'
  end
  
  def all_urls
    self.class.all_urls
  end
  
  def save
    if validate
      set_id
      $redis.set(key, @url)
      $redis.set(reverse_key, @id)
      $redis.lpush(all_urls, @id)
      self
    else
      false
    end
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
  
  def validate
    check_invalid_urls
  end
  
  def check_invalid_urls
    ['tinyurl.com', 'bit.ly', 'j.mp', 'f0rk.me', 'tr.im', 'rubyurl.com'].each do |url|
      return false if self.url.match(/http:\/\/#{url}/)
    end
  end
end