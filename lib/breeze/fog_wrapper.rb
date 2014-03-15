require 'breeze/fog_extensions'
module Breeze

  # The fog wrapper makes it possible for subsequent shell commands
  # to share the same fog mock session. If Fog.mocking? is true, the
  # mock data is read from and written to a yaml file.
  module FogWrapper

    def self.connection(type)
      {compute: Compute, dns: DNS, rds: RDS, elasticache: Elasticache, elb: ELB}[type].get_connection
    end

    def self.flush_mock_data!
      Compute.new.flush_data!
      DNS.new.flush_data!
      # RDS.new.flush_data!
    end

    class AbstractConnectionWrapper

      def self.get_connection
        Fog.mocking? ? new : direct_fog_connection
      end

      def method_missing(*args)
        load_data
        return_value = fog.send(*args)
        flush_data!
        return_value
      end

      def flush_data!
        File.open(data_file, 'w') { |f| YAML::dump(get_data, f) }
      end

      private

      def fog
        @fog ||= self.class.direct_fog_connection
      end
      def load_data
        set_data(YAML::load_file(data_file)) if File.exists?(data_file)
      end
      def get_data
        mock_class.instance_variable_get('@data')
      end
      def set_data(data)
        mock_class.instance_variable_set('@data', data)
      end
    end

    class Compute < AbstractConnectionWrapper
      def self.direct_fog_connection
        Fog::Compute.new(CONFIGURATION[:cloud_service])
      end
      private
      def data_file  ; 'fog_compute_data.yaml' ; end
      def mock_class ; Fog::Compute::AWS::Mock ; end
    end

    class DNS < AbstractConnectionWrapper
      def self.direct_fog_connection
        Fog::DNS.new(CONFIGURATION[:cloud_service])
      end
      private
      def data_file  ; 'fog_dns_data.yaml' ; end
      def mock_class ; Fog::DNS::AWS::Mock ; end
    end

    # TODO: add RDS mocks to fog so that we can start testing it
    class RDS < AbstractConnectionWrapper
      def self.direct_fog_connection
        credentials = CONFIGURATION[:cloud_service].reject{ |k,v| k == :provider }
        credentials[:region] = CONFIGURATION[:db_region]
        Fog::AWS::RDS.new(credentials)
      end
      private
      def data_file  ; 'fog_rds_data.yaml' ; end
      def mock_class ; Fog::AWS::RDS::Mock ; end
    end

    class Elasticache < AbstractConnectionWrapper
      def self.direct_fog_connection
        Fog::AWS::Elasticache.new(CONFIGURATION[:cloud_service])
      end
      private
      def data_file  ; 'fog_elasticache_data.yaml' ; end
      def mock_class ; Fog::AWS::Elasticache::Mock ; end
    end

    class ELB < AbstractConnectionWrapper
      def self.direct_fog_connection
        Fog::AWS::ELB.new(CONFIGURATION[:cloud_service])
      end
      private
      def data_file  ; 'fog_elb_data.yaml' ; end
      def mock_class ; Fog::AWS::ELB::Mock ; end
    end

  end
end
