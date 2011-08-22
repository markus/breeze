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

    desc 'destroy INSTANCE_ID [...]', 'Terminate a running (or stopped) server instance'
    method_options :force => false
    def destroy(*instance_ids)
      instance_ids.each do |instance_id|
        server = fog.servers.get(instance_id)
        if force_or_accept?("Terminate server #{server.display_name}?")
          server.destroy
        end
      end
    end

    private

    def create_server(options=nil)
      options ||= CONFIGURATION[:default_server_options]
      # puts("Server options: #{options.inspect}")
      server = fog.servers.create(options)
      print "Launching server #{server.id}"
      wait_until('running!') { server.running? }
      FogWrapper.flush_mock_data! if Fog.mocking?
      return server
    end

    # Can take a host name or an ip address. Resolves the host name
    # and returns the ip address if get_ip is passed in as true.
    def wait_until_host_is_available(host, get_ip=false)
      resolved_host = Resolv.getaddresses(host).first
      if resolved_host.nil?
        print("Waiting for #{host} to resolve")
        wait_until('ready!') { resolved_host = Resolv.getaddresses(host).first }
      end
      host = resolved_host if get_ip
      unless remote_is_available?(host)
        print("Waiting for #{host} to accept connections")
        wait_until('ready!') { remote_is_available?(host) }
      end
      return host
    end

    def remote_is_available?(host)
      execute("%{ssh_command} -q %{ssh_user}@%{host} exit", :host => host)
    end

    # Execute a command on the remote host. Args is a hash that must include :host.
    def remote(command, args)
      args[:command] = command
      execute("%{ssh_command} %{ssh_user}@%{host} '%{command}'", args)
    end

    def upload(file_pattern, args)
      args[:file_pattern] = file_pattern
      args[:remote_path] ||= './'
      execute('rsync -e "%{ssh_command}" -v %{file_pattern} %{ssh_user}@%{host}:%{remote_path}', args)
    end

    def download(remote_path, args)
      args[:remote_path] = remote_path
      args[:local_path] ||= './'
      execute('rsync -e "%{ssh_command}" -v %{ssh_user}@%{host}:%{remote_path} %{local_path}', args)
    end

    def execute(command, args)
      args = CONFIGURATION[:ssh].merge(args)
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
