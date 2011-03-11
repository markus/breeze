module Breeze

  class Server::Tag < Veur

    desc 'create SERVER_ID KEY VALUE', 'Create a tag'
    def create(server_id, key, value)
      fog.tags.create(:resource_id => server_id, :key => key, :value => value)
    end

    desc 'destroy SERVER_ID KEY', 'Delete a tag'
    def destroy(server_id, key)
      fog.tags.get(key).detect{ |tag| tag.resource_id == server_id }.destroy
    end

  end
end
