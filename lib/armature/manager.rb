require 'logger'

module Armature
  class Manager
    def initialize(redis, logger=Logger.new(STDOUT))
      @redis = redis
      @log = logger
    end

    def exists?(instance_id)
      ! list_metrics(instance_id).empty?
    end

    def add_metric(instance_id, metric)
      results = @redis.multi do
        @redis.sadd(metrics_key(instance_id), metric.id)
        @redis.hmset(metric_key(instance_id, metric.id), metric.to_h.flatten)
      end
    end
    
    def destroy_metric(instance_id, metric_id)
      results = @redis.multi do
        dangerous_destroy_metric(instance_id, metric_id)
      end
    end

    def get_metric(instance_id, metric_id)
      data = @redis.hgetall(metric_key(instance_id, metric_id))
      return if data.empty?
      Metric.convert_hash!(data)
      Metric.new(metric_id, data['name'], data['description'], data['weight'], data['status'])
    end

    def destroy(instance_id)
      keys = list_metrics # can't iterate over redis futures
      results = @redis.multi do
        @redis.del(metrics_key(instance_id))
        keys.each do |k|
          dangerous_destroy_metric(instance_id, k)
        end
      end
    end

    def list_metrics(instance_id)
      @redis.smembers(metrics_key(instance_id))
    end

    def iter_metrics(instance_id)
      Enumerator.new do |yielder|
        list_metrics(instance_id).each do |metric_id|
          yielder.yield get_metric(instance_id, metric_id)
        end
      end
    end

    def all_metrics(instance_id)
      iter_metrics(instance_id).to_a
    end

    def healthy?(instance_id)
      iter_metrics(instance_id).each do |m|
        # short-circuit if any are unhealthy
        return false if ! m.healthy?
      end
    end

    def to_json(instance_id)
      all_metrics(instance_id).map(&:to_h).to_json 
    end

    private

    def prefix(instance_id)
      "armature:#{instance_id}"
    end

    def metrics_key(instance_id)
      # armature:<instance_id>:_metrics
      prefix(instance_id) + ":_metrics"
    end

    def metric_key(instance_id, metric_id)
      # armature:<instance_id>:<metric_id>
      prefix(instance_id) + ':' + metric_id
    end

    def metric_keys(instance_id)
      list_metrics.map { |x| metric_key(instance_id, x) }
    end

    def dangerous_destroy_metric(instance_id, metric_id)
      # dangerous because it's not in a transaction
      @redis.srem(metrics_key(instance_id), metric_id)
      @redis.del(metric_key(instance_id, metric_id))
    end
  end
end
