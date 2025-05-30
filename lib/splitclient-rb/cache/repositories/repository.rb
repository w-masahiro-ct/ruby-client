module SplitIoClient
  module Cache
    class Repository

      def initialize(config)
        @config = config
      end

      def set_string(key, str)
        @adapter.set_string(namespace_key(key), str)
      end

      def string(key)
        @adapter.string(namespace_key(key))
      end

      protected

      def namespace_key(key = '')
        "#{@config.redis_namespace}#{key}"
      end
    end
  end
end
