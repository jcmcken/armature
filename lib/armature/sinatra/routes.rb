require 'sinatra/base'
require 'sinatra/respond_to'
require 'armature'
require 'json'

module Armature
  class App < Sinatra::Base
    register Sinatra::RespondTo

    get '/instances/:instance_id' do
      respond_to do |wants|
#        wants.html do
#          @metrics = db.all_metrics(params[:instance_id])
#          erb :instance
#        end
        wants.json { db.to_json(params[:instance_id]) }
      end
    end

    get '/instances/:instance_id/metrics' do
      @metrics = db.list_metrics(params[:instance_id])
      respond_to do |wants|
        wants.json { @metrics.to_json }
      end
    end

    get '/instances/:instance_id/metrics/:metric_id' do
      @metric = db.get_metric(params[:instance_id], params[:metric_id])
      halt 404 if ! @metric
      respond_to do |wants|
        wants.json { @metric.to_json }
      end
    end
  
    get '/instances/:instance_id/status' do
      db.healthy?(params[:instance_id]) ? halt(200) : halt(444)
    end
  end
end
