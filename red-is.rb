require 'redis_url'
require 'haml'

get '/' do
  erb :index
end

post '/' do
  @url = RedisUrl.create(params[:url])
  erb :index
end

get '/favicon.ico' do
end

get %r{/(.+)} do |url|
  u = RedisUrl.find(url)
  u.clicked
  redirect u.url
end
