require 'fog/aws/models/compute/server'
require 'fog/aws/models/compute/image'

module Fog
  module AWS
    class Compute
      class Server
        def name
          breeze_data['name'] || tags['Name']
        end

        def display_name
          return "#{state}:#{name}" if name and state != 'running'
          name || public_ip_address || "#{state} #{flavor_id} #{id}"
        end

        def running? ; current_state == 'running' ; end
        def stopped? ; current_state == 'stopped' ; end

        # Get or set meta data that is saved in a tag.
        def breeze_data(new_values=nil)
          if new_values
            tags['breeze-data'] = new_values.map{ |k,v| v.nil? ? v : "#{k}:#{v}" }.compact.join(';')
            # thor("server:tag:create #{id} breeze-data '#{tags['breeze-data']}'")
            Breeze::Server::Tag.new.create(id, 'breeze-data', tags['breeze-data'])
          else
            Hash[tags['breeze-data'].to_s.split(';').map{ |s| s.split(':') }]
          end
        end

        def spare_for_rollback!
          breeze_state('spare_for_rollback')
        end

        def spare_for_rollback?
          breeze_state == 'spare_for_rollback'
        end

        # Get or set the state tag.
        def breeze_state(new_state=nil)
          if new_state
            breeze_data(breeze_data.merge('state' => new_state))
          else
            breeze_data['state']
          end
        end

        private

        def current_state
          reload
          state
        end

      end
      class Image

        def display_name
          name or location
        end

        def full_type
          "#{type}, #{architecture}, #{root_device_type}"
        end

      end
    end
  end
end
