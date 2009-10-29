require 'redis'
require 'haml'

$redis = Redis.new

class RedisUrl
  attr_accessor :url, :id
  
  def initialize(url = nil)
    @url = url
  end

  def self.find(url)
    u = $redis.get(key(url))
    redis_url = RedisUrl.new(u)
    redis_url.id = url
    redis_url
  end
  
  def self.key(id)
    "red.is.url.#{id}"
  end
  
  def key
    self.class.key(@id)
  end
  
  def clicked
    redis.setnx("red.is.url.#{id}.clicks", '0')
    redis.incr("red.is.url.#{id}.clicks")
  end
  
  def save
    set_id
    redis.set(key, @url)
    self
  end
  
  def seeded(id)
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
    redis.setnx(counter, '0')
    @id = seeded(redis.incr(counter))
  end
  
  def redis
    $redis
  end
end

use_in_file_templates!

get '/' do
  haml :index
end

post '/' do
  @url = RedisUrl.new(params[:url]).save
  haml :index
end

get %r{/(.+)} do |url|
  u = RedisUrl.find(url)
  u.clicked
  redirect u.url
end

__END__
 
@@ layout
!!! 1.1
%html
  %head
    %title red.is
    %link{:rel => 'stylesheet', :href => 'http://www.w3.org/StyleSheets/Core/Modernist', :type => 'text/css'}  
  = yield
 
@@ index
%h1.title red.is
- unless @url.nil?
  %code= @url.url
  red.is'd to 
  %a{:href => env['HTTP_REFERER'] + @url.id}
    = env['HTTP_REFERER'] + @url.id
#err.warning= env['sinatra.error']
%form{:method => 'post', :action => '/'}
  URL:
  %input{:type => 'text', :name => 'url', :size => '50'} 
  %input{:type => 'submit', :value => 'red.is!'}
%small copyright &copy;
%a{:href => 'http://paperplanes.de'}
  Mathias Meyer
%br
%br
  %a{:href => 'http://code.google.com/p/redis'}
    Based on Redis
  %br
  %a{:href => 'http://github.com/mattmatt/red.is'}
    Full source code