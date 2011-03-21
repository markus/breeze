require 'resolv'

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
      if force_or_accept?("Terminate server #{server.display_name}?")
        server.destroy
      end
    end

    private

    def create_server(options=nil)
      options ||= CONFIGURATION[:default_server_options]
      # puts("Server options: #{options.inspect}")
      server = fog.servers.create(options)
      print "Launching server #{server.id}"
      wait_until('running!') { server.running? }
      return server
    end

    def wait_until_host_is_available(host)
      if Resolv.getaddresses(host).empty?
        print("Waiting for #{host} to resolve")
        wait_until('ready!') { Resolv.getaddresses(host).any? }
      end
      return true if remote_is_available?(host)
      print("Waiting for #{host} to accept connections")
      wait_until('ready!') { remote_is_available?(host) }
    end

    def remote_is_available?(host)
      execute(:remote_available?, :host => host)
    end

    def remote(command, args)
      args[:command] = command
      execute(:remote_command, args)
    end

    def upload(file_pattern, args)
      args[:file_pattern] = file_pattern
      execute(:upload_command, args)
    end

    def execute(command, args)
      command = CONFIGURATION[command] if command.is_a?(Symbol)
    #   system(command % args)
    # rescue ArgumentError # for ruby 1.8 compatibility
      args.each do |key, value|
        command = command.gsub("%{#{key}}", value)
      end
      system(command)
    end

  end
end
