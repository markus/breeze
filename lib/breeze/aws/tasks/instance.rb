module Breeze
  module Aws

    # Dealing with EC2 server instances.
    class Instance < Veur

      desc 'launch', 'Launch a new server instance on Amazon EC2'
      method_options  :image_id           => CONFIGURATION[:default_ami],
                      :key_name           => CONFIGURATION[:key_pair_name],
                      :flavor_id          => CONFIGURATION[:default_instance_type],
                      :availability_zone  => CONFIGURATION[:default_availability_zone],
                      :user_data_file     => :string
      def launch
        if options[:user_data_file]
          options[:user_data] = Base64.encode64(File.read(options[:user_data_file])).strip
        end
        puts("Launch options: #{options.inspect}")
        instance = fog.servers.create(options)
        print "Launching instance #{instance.id}"
        wait_until('running!'){ instance.reload; instance.ready? }
      end

      desc 'terminate INSTANCE_ID', 'Terminate a running EC2 instance'
      method_options :force => false
      def terminate(instance_id)
        instance = fog.servers.get(instance_id)
        if options[:force] or accept?("Terminate instance #{instance.ip_address}?")
          print "Instance #{instance.id} currently #{instance.state}... "
          instance.destroy
          puts "now #{instance.reload.state}."
        end
      end

    end
  end
end
