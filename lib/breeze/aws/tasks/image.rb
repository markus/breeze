module Breeze
  module Aws

    # Dealing with Amazon Machine Images (AMIs)
    class Image < Veur

      desc 'create', 'Launch an instance with the base ami, wait for the new instance to boot, invoke prepare_private_ami(ip_address), ' +
                     'stop the instance, create a new AMI as a snapshot of the EBS drive, and terminate the instance.'
      method_options  :image_id           => CONFIGURATION[:base_ami],
                      :key_name           => CONFIGURATION[:key_pair_name],
                      :flavor_id          => CONFIGURATION[:default_instance_type],
                      :availability_zone  => CONFIGURATION[:default_availability_zone],
                      :size               => CONFIGURATION[:ebs_volume_size]
      def create
        options[:block_device_mapping] = [{:device_name => '/dev/sda1', :ebs_volume_size => options.delete(:size)}]
        instance = create_instance(options)
        Breeze.prepare_private_ami(instance.ip_address)
        print('Stopping the instance before saving a snapshot')
        instance.stop
        wait_until('stopped!') { instance.reload; instance.state == 'stopped' }
        thor('breeze:aws:describe:images')
        image = fog.images.create(:name => ask('Image name >'), :instance_id => instance.id)
        instance.destroy
        puts
        puts("===> Created image #{image.id} and terminated temporary server #{instance.id}.")
        puts
        puts("NOTICE: it may take a while before the new image shows up in aws:describe:images")
      end

    end
  end
end
