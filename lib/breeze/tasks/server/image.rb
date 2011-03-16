require 'breeze/tasks/server'

module Breeze

  # Dealing with machine images.
  class Server::Image < Server
    desc 'create', 'Launch a server with the base image, wait for it to boot, invoke prepare_private_image(ip_address), ' +
                   'stop the server, create a new machine image as a snapshot of the root device, and destroy the server.'
    method_options CONFIGURATION[:default_server_options].merge(CONFIGURATION[:create_image_options])
    def create
      options[:block_device_mapping] = [{:device_name => '/dev/sda1', :ebs_volume_size => options.delete(:root_device_size)}]
      server = create_server(options)
      prepare_private_image(server.public_ip_address)
      print('Stopping the server before saving a snapshot')
      server.stop
      wait_until('stopped!') { server.stopped? }
      thor('list:images')
      image = fog.images.create(:name => ask('Image name >'), :instance_id => server.id)
      server.destroy
      puts
      puts("===> Created image #{image.id} and terminated temporary server #{server.id}.")
      puts
      puts("NOTICE: it may take a while before the new image shows up in list:images")
    end

  end
end
