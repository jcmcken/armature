require 'json'

module Armature
  class Metric
    attr_reader :id, :name, :description, :weight

    def initialize(id, name=nil, description=nil, weight=1.0, status=:bad)
      @id = id
      @name = name || @id
      @description = description || ''
      @weight = weight
      @status = status.to_sym
      validate_params
    end

    def self.convert_hash!(data)
      data['weight'] = data['weight'].to_f
      data['status'] = data['status'].to_sym
    end

    def downgrade!
      @status = :bad
    end

    def upgrade!
      @status = :good
    end

    def healthy?
      case @status
      when :bad
        false
      when :good
        true
      end
    end

    def to_h
      {
        :name => @name,
        :description => @description,
        :weight => @weight.to_s,
        :status => @status.to_s,
      }
    end

    def to_json
      to_h.to_json
    end

    private

    def validate_params
      if @id !~ /^[a-zA-Z]/
        raise ArgumentError, '"id" must start with a letter'
      end
      if ! [Fixnum, Float].include?(@weight.class) or @weight < 0 or @weight > 1
        raise ArgumentError, '"weight" must be a float between 0 and 1'
      end
    end
  end
end
