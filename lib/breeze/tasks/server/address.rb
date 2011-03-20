module Breeze

  # Aka Amazon Elastic IP
  class Server::Address < Veur

    desc 'create SERVER_ID', 'Create and associate a new elastic ip'
    def create(server_id)
      # TODO: fog should take server_id directly when creating an address
      server = fog.servers.get(server_id)
      fog.addresses.create(:server => server)
    end

    desc 'release IP', 'Release the ip address'
    method_options :force => false
    def release(ip)
      if force_or_accept?("Release IP #{ip}?")
        fog.addresses.get(ip).destroy
      end
    end

    desc 'associate IP NEW_SERVER_ID', 'Associate an existing IP with a new server'
    def associate(ip, server_id)
      fog.associate_address(server_id, ip)
    end

  end
end
