require 'breeze/aws/connection'

module Breeze
  module Aws

    # Represents one EC2 instance and provides access to its attributes.
    # May reload data from AWS.
    class Ec2Instance

      DEFAULT_OPTIONS = {
        :image_id           => CONFIGURATION[:default_ami],
        :key_name           => CONFIGURATION[:key_pair_name],
        :instance_type      => CONFIGURATION[:default_instance_type],
        :availability_zone  => CONFIGURATION[:default_availability_zone]
      }

      include Connection
      attr_reader :id, :instance_data

      def self.launch!(options)
        new(nil).send(:launch!, DEFAULT_OPTIONS.merge(options))
      end

      def initialize(instance_id)
        @id = instance_id
      end

      def running?
        state == 'running'
      end

      def stopped?
        state == 'stopped'
      end

      def public_ip
        instance_data.string('ipAddress')
      end

      def stop!
        aws.stop_instances(:instance_id => @id)
      end

      # send termination request and return the new instance_data
      def terminate!
        extract_instance_data(aws.terminate_instances(:instance_id => @id))
      end

      private

      # a helper for the class method
      def launch!(options)
        puts("launch options: #{options.inspect}")
        extract_instance_data(aws.run_instances(options))
        @id = @instance_data['instanceId']
        return self
      end

      def state
        instance_data(true).string('instanceState name')
      end

      def instance_data(reload=false)
        (reload || @instance_data.nil?) ? fetch_instance_data : @instance_data
      end

      def fetch_instance_data
        extract_instance_data(aws.describe_instances(:instance_id => @id).first_hash('reservationSet item'))
      end

      def extract_instance_data(response)
        @instance_data = response.first_hash('instancesSet item')
      end

    end
  end
end
