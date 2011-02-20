module Breeze
  module Aws

    # Dealing with Amazon Machine Images (AMIs)
    class Image < AwsVeur

      desc 'create', 'Launch an instance with the base ami, wait for the new instance to boot, invoke prepare_private_ami(ip_address), ' +
                     'stop the instance, create a new AMI as a snapshot of the EBS drive, and terminate the instance.'
      def create
        instance = Ec2Instance.launch!(
          :image_id => CONFIGURATION[:base_ami],
          :block_device_mapping => [{:device_name => '/dev/sda1', :ebs_volume_size => CONFIGURATION[:ebs_volume_size]}]
        )
        print("Launching a new instance")
        wait_until('running!') { instance.running? }
        Breeze.prepare_private_ami(instance.public_ip)
        print('Stopping the instance before saving a snapshot')
        instance.stop!
        wait_until('stopped!') { instance.stopped? }
        response = aws.create_image(:name => ask('Image name >'), :instance_id => instance.id)
        puts
        puts("================> Created image: #{response.string('imageId')}")
        puts
        thor 'aws:instance:terminate', instance.id, :force => true
        puts
        puts("NOTICE: it may take a while before the new image shows up in describe:images")
      end

    end
  end
end
