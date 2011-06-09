require 'rubygems'
require 'sinatra'

set :run, false
set :environment, :production

require './app.rb'
run Sinatra::Application
