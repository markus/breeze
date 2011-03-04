module Breeze

  # Dealing with server instances.
  class Server < Veur

    desc 'create', 'Launch a new server instance'
    method_options CONFIGURATION[:default_server_options]
    def create
      if options[:user_data_file]
        options[:user_data] = Base64.encode64(File.read(options[:user_data_file])).strip
      end
      create_server(options)
    end

    desc 'destroy INSTANCE_ID', 'Terminate a running (or stopped) server instance'
    method_options :force => false
    def destroy(instance_id)
      server = fog.servers.get(instance_id)
      if options[:force] or accept?("Terminate server #{server.display_name}?")
        print "Instance #{server.id} currently #{server.state}... "
        server.destroy
        puts "now #{server.reload.state}."
      end
    end

    private

    def create_server(options)
      puts("Launch options: #{options.inspect}")
      server = fog.servers.create(options)
      print "Launching server #{server.id}"
      wait_until('running!') { server.running? }
      return server
    end

  end
end
