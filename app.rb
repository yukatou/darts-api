# -*- encoding: UTF-8 -*-

require 'rubygems'
require 'sinatra'
require 'json'
require 'base64'
require 'nokogiri'
require 'dalli'
require './lib/dartslive'

cache = Dalli::Client.new('localhost:11211')
set :raise_errors, false 
#
# configure
#
configure do
end


#
# action
#
get '/profile' do
  unless result = cache.get(cache_key)
    dl = DartsLive.new(@cardno, @passwd)
    result = dl.getCardInfo()
    cache.set(cache_key, result, 60 * 5)
  end
  api_render result
end

post '/stats' do
  unless result = cache.get(cache_key)
    dl = DartsLive.new(@cardno, @passwd)
    result = dl.getStats()
    cache.set(cache_key, result, 60 * 5)
  end
  api_render result
end

post '/award' do
  unless result = cache.get(cache_key)
    dl = DartsLive.new(@cardno, @passwd)
    result = dl.getAward()
    cache.set(cache_key, result, 60 * 5)
  end
  api_render result
end

post '/countup' do
  unless result = cache.get(cache_key)
    dl = DartsLive.new(@cardno, @passwd)
    result = dl.getAward()
    cache.set(cache_key, result, 60 * 5)
  end
  api_render result
end

before do
  halt 400, 'Bad request' unless params[:id]
  @cardno, @passwd = Base64.decode64(params[:id]).split(':')
end

after do
end

#
# ERROR
#

error AuthError do
  halt 401, env['sinatra.error'].message
end

error NotFoundError do
  halt 404, env['sinatra.error'].message
end

error InternalError do
  halt 500, env['sinatra.error'].message
end

error RuntimeError do
  halt 500, env['sinatra.error'].message
end

error 400..404 do
  message = {400 => 'Bad Request', 
             401 => 'Unauthorized',
             404 => 'Not Found' }

  h = {:status => response.status, :message => message[response.status], :detail => response.body}
  api_render h
end

error 500 do
  h = {:status => response.status, :message => 'Internal Server Error', :detail => response.body}
  api_render h
end


def api_render (hash)
=begin
  case request.accept.first
  when mime_type(:json)
    content_type :json
    hash.to_json
  when mime_type(:xml)
    content_type :xml
    obj = Nokogiri::XML::Builder.new do |xml|
      xml.result {
        hash.each{ |k, v|
          eval("xml.#{k} { xml.text v }")
        }
      }
    end
    obj.to_xml
  when
    hash[:detail]
  end
=end
hash.to_json
end

def cache_key 
  "#{request.path_info}.#{params[:id]}"
end
