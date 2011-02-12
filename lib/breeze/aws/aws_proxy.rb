require 'AWS' unless defined?(AWS)

module Breeze
  module Aws

    # Turn responses into ResponseHash objects.
    class AwsProxy

      def method_missing(method, *args)
        ResponseHash.new(connection.send(method, *args))
      end

      private

      def connection
        @connection ||= AWS::EC2::Base.new(credentials)
      end

      def credentials
        CONFIGURATION.reject{ |k,v| ![:access_key_id, :secret_access_key].include?(k) }
      end
    end
  end
end
