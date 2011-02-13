require 'breeze/aws/connection'

module Breeze
  module Aws

    # Represents one EC2 instance and provides access to its attributes.
    # May reload data from AWS.
    class Ec2Instance

      include Connection
      attr_reader :id

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

      def terminate!
        aws.terminate_instances(:instance_id => @id)
      end

      private

      def state
        instance_data(true).string('instanceState name')
      end

      def instance_data(reload=false)
        @instance_data = (reload || @instance_data.nil?) ? fetch_instance_data : @instance_data
      end

      def fetch_instance_data
        aws.describe_instances(:instance_id => @id).first_hash('reservationSet item').first_hash('instancesSet item')
      end
    end
  end
end
