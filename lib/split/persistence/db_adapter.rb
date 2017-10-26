# frozen_string_literal: true
module Split
  module Persistence
    class DbAdapter
      DEFAULT_CONFIG = {:namespace => 'persistence'}.freeze

      attr_reader :redis_key

      def initialize(context, key = nil)
        binding.pry
        if key
          @redis_key = "#{self.class.config[:namespace]}:#{key}"
        elsif lookup_by = self.class.config[:lookup_by]
          if lookup_by.respond_to?(:call)
            key_frag = lookup_by.call(context)
          else
            key_frag = context.send(lookup_by)
          end
          @redis_key = "#{self.class.config[:namespace]}:#{key_frag}"
        else
          raise "Please configure lookup_by"
        end
      end

      def [](field)
        Split.redis.hget(redis_key, field)
      end

      def []=(field, value)
        Split.redis.hset(redis_key, field, value)
        expire_seconds = self.class.config[:expire_seconds]
        Split.redis.expire(redis_key, expire_seconds) if expire_seconds
      end

      def delete(field)
        Split.redis.hdel(redis_key, field)
      end

      def keys
        Split.redis.hkeys(redis_key)
      end

      def self.with_config(options={})
        self.config.merge!(options)
        self
      end

      def self.config
        @config ||= DEFAULT_CONFIG.dup
      end

      def self.reset_config!
        @config = DEFAULT_CONFIG.dup
      end

    end
  end
end
