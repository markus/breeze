module Breeze
  module Aws

    # Represents one EC2 instance and provides access to its attributes.
    # May reload data from AWS.
    class Ec2Instance

      def initialize(instance_id)
        @instance_id = instance_id
      end

      def running?
        state == 'running'
      end

      def public_ip
        instance_data.string('ipAddress')
      end

      private

      def state
        instance_data(true).string('instanceState name')
      end

      def instance_data(reload=false)
        @instance_data = (reload || @instance_data.nil?) ? fetch_instance_data : @instance_data
      end

      def fetch_instance_data
        Aws.connection.describe_instances(:instance_id => @instance_id).first_hash('reservationSet item').first_hash('instancesSet item')
      end

    end
  end
end
