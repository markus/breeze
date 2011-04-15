require 'breeze/tasks/server'

module Breeze

  # Dealing with machine images.
  class Server::Image < Server
    desc 'create', 'Launch a server with the base image, wait for it to boot, invoke prepare_private_image(ip_address), ' +
                   'stop the server, create a new machine image as a snapshot of the root device, and destroy the server.'
    method_options CONFIGURATION[:default_server_options].merge(CONFIGURATION[:create_image_options])
    def create
      # The commented lines used to work before fog 0.7.0.
      # options[:block_device_mapping] = [{:device_name => '/dev/sda1', :ebs_volume_size => options.delete(:root_device_size)}]
      options[:block_device_mapping] = [{'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => options.delete(:root_device_size)}]
      server = create_server(options)
      prepare_private_image(server.public_ip_address)
      print('Stopping the server before saving a snapshot')
      server.stop
      wait_until('stopped!') { server.stopped? }
      thor('describe:images')
      puts('===== Old server images are listed above. Give a name to the new image. =====')
      # image = fog.images.create(:name => ask('Image name >'), :instance_id => server.id)
      fog.create_image(server.id, ask('Image name >'), '')
      server.destroy
      puts
      # puts("===> Created image #{image.id} and terminated temporary server #{server.id}.")
      puts("===> Created a new server image and terminated temporary server #{server.id}.")
      puts
      puts("NOTICE: it may take a while before the new image shows up in describe:images")
    end

    desc 'destroy IMAGE_ID', 'Deregister the image and destroy the related volume snapshot'
    method_options :force => false
    def destroy(*image_ids)
      image_ids.each do |image_id|
        image = fog.images.get(image_id)
        if force_or_accept?("Destroy image #{image.display_name}?")
          image.deregister(true)
        end
      end
    end

  end
end
