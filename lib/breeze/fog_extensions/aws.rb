require 'fog/compute/models/aws/server'
require 'fog/compute/models/aws/image'

module Fog

  module AWS
    class Compute::Server

      def name
        breeze_data['name'] || tags['Name']
      end

      def display_name
        name || public_ip_address || "#{state} #{flavor_id} #{id}"
      end

      def running? ; current_state == 'running' ; end
      def stopped? ; current_state == 'stopped' ; end

      # Get or set meta data that is saved in a tag.
      # NOTICE: the tag is not saved automatically!
      def breeze_data(new_values=nil)
        if new_values
          tags['breeze-data'] = new_values.map{ |k,v| v.nil? ? v : "#{k}:#{v}" }.compact.join(';')
        else
          Hash[tags['breeze-data'].to_s.split(';').map{ |s| s.split(':') }]
        end
      end

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
