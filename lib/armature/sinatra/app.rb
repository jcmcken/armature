require 'rubygems'
require 'sinatra/base'
require 'sinatra/config_file'
require 'redis'
$LOAD_PATH << File.join(File.dirname(__FILE__), '../../../lib')
require 'armature'
require 'armature/sinatra'

module Armature
  class App < Sinatra::Base
    register Sinatra::ConfigFile

    config_file File.join(File.dirname(__FILE__), '../../../config/armature.yml')

    configure do
      set :app_file, __FILE__
      set :db, Manager.new(Redis.new(settings.redis || {}))
    end
    
    configure :development do
      enable :logging, :dump_errors, :raise_errors
    end
  
    configure :production do
      set :raise_errors, false
      set :show_exceptions, false
    end

    def db
      settings.db
    end
  end
end
