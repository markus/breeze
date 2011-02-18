module Breeze
  module Aws

    # Dealing with Amazon Machine Images (AMIs)
    class Image < AwsVeur

      desc 'create IMAGE_NAME', 'Launch an instance with the base ami, ' +
                                'wait for the new instance to boot, ' +
                                'invoke prepare_private_ami(ip_address), ' +
                                'stop the instance, create a new AMI as a snapshot of the EBS drive, and terminate the instance.'
      def create(image_name)
        instance = Ec2Instance.new(create_instance)
        wait_until('running!') { instance.running? }
        Breeze.prepare_private_ami(instance.public_ip)
        puts('Stopping the instance before saving a snapshot')
        instance.stop!
        wait_until('stopped!') { instance.stopped? }
        response = aws.create_image(:name => image_name, :instance_id => instance.id)
        puts
        puts("================> Created image: #{response.string('imageId')}")
        puts
        terminate_instance(instance.id)
        puts
        puts("NOTICE: it may take a while before the new image shows up in describe:images")
      end

      private

      def create_instance
        Instance.new.launch(:image_id => CONFIGURATION[:default_base_ami])
      end

      def terminate_instance(instance_id)
        Instance.new.terminate(instance_id, :force => true)
      end
    end
  end
end