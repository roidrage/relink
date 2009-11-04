require 'httpauth'
require 'redis_url'

enable :sessions

get '/' do
  erb :index
end

post '/' do
  login_required
  @url = RedisUrl.find_or_create(params[:url])
  erb :index
end

post '/t' do
  login_required
  "http://#{env['HTTP_HOST']}/#{RedisUrl.find_or_create(params[:url]).id}"
end

get '/favicon.ico' do
end

get '/list' do
  login_required
  @urls = RedisUrl.all
  erb :list
end

get '/p/:url' do |url|
  login_required
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
