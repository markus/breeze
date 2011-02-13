module Breeze
  module Aws

    # Dealing with EC2 server instances.
    class Instance < AwsVeur

      desc 'launch', 'Launch a new server instance on EC2'
      method_options  :image_id           => CONFIGURATION[:default_ami],
                      :key_name           => CONFIGURATION[:key_pair_name],
                      :instance_type      => CONFIGURATION[:default_instance_type],
                      :availability_zone  => CONFIGURATION[:default_availability_zone],
                      :user_data_file     => :string
      def launch
        if options[:user_data_file]
          options[:user_data] = File.read(options[:user_data_file])
          options[:base64_encoded] = true
        end
        puts("launch options: #{options.inspect}")
        extract_instances(aws.run_instances(options))
        additional_report_fields = [
          ['State', 'instanceState name']
        ]
        report('LAUNCHING', additional_report_fields)
        return @instances.first['instanceId']
      end

      desc 'terminate INSTANCE_ID', 'Terminate a running EC2 instance'
      method_options :force => false
      def terminate(instance_id)
        if options[:force] or accept?("Terminate instance #{instance_id}?")
          extract_instances(aws.terminate_instances(:instance_id => [instance_id]))
          additional_report_fields = [
            ['Previous State', 'previousState name'],
            ['Current State', 'currentState name']
          ]
          report('TERMINATED', additional_report_fields)
        end
      end

      private

      def extract_instances(response)
        @instances = response.array('instancesSet item')
      end

      def report(title, spec)
        spec.unshift(['Instance ID', 'instanceId'])
        super(title, ReportTable.create(spec, @instances))
      end

    end
  end
end
