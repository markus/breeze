require 'fog/compute/models/aws/server'
require 'fog/compute/models/aws/image'

module Fog

  module AWS
    class Compute::Server

      def name
        tags['Name']
      end

      def display_name
        name || ip_address || "#{state} #{flavor_id} #{id}"
      end

      def running? ; current_state == 'running' ; end
      def stopped? ; current_state == 'stopped' ; end

      private

      def current_state
        reload
        state
      end

    end
    class Compute::Image

      def full_type
        "#{type}, #{architecture}, #{root_device_type}"
      end

    end
  end

end
