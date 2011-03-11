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
    def destroy(ip)
      fog.addresses.get(ip).destroy
    end

  end
end
