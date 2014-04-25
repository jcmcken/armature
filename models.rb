require 'redis'

module Armature
  class Instance
    def initialize(redis, instance_id)
      @redis = redis
      @instance_id = instance_id
    end

    def exists?
      !!list_metrics
    end

    def prefix
      "armature:#{@instance_id}"
    end

    def metrics_key
      # armature:<instance_id>:_metrics
      prefix + ":_metrics"
    end

    def metric_key(metric_name)
      # armature:<instance_id>:<metric_name>
      prefix + ':' + metric_name
    end

    def add_metric(metric)
      results = @redis.multi do
        @redis.sadd(metrics_key, metric.id)
        @redis.hmset(metric_key(metric.id), metric.to_h.flatten)
      end
    end
    
    def destroy_metric(metric_id)
      results = @redis.multi do
        @redis.srem(metrics_key, metric_key(metric_id))
        @redis.del(metric_key(metric_id))
      end
    end

    def get_metric(metric_id)
      data = @redis.hgetall(metric_key(metric_id))
      return if data.empty?
      Metric.new(metric_id, data['name'], data['description'], data['weight'].to_f)
    end

    def destroy
      keys = list_metrics # can't iterate over redis futures
      results = @redis.multi do
        keys.each do |k|
          destroy_metric(k)
        end
        @redis.del(metrics_key)
      end
    end

    def list_metrics
      @redis.smembers(metrics_key)
    end

    private

    def metric_keys
      list_metrics.map { |x| metric_key(x) }
    end
  end
end
