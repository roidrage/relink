require 'redis_url'
require 'haml'

get '/' do
  erb :index
end

post '/' do
  @url = RedisUrl.find_or_create(params[:url])
  erb :index
end

get '/favicon.ico' do
end

get '/p/:url' do |url|
  @url = RedisUrl.find(url)
  if @url
    erb :preview
  else
    status 404
    erb :not_found
  end
end

get %r{/(.+)} do |url|
  u = RedisUrl.find(url)
  if u
    u.clicked
    redirect u.url
  else
    status 404
    erb :not_found
  end
end
