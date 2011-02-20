module Breeze
  module Aws

    # Dealing with EC2 server instances.
    class Instance < AwsVeur

      desc 'launch', 'Launch a new server instance on Amazon EC2'
      method_options  Ec2Instance::DEFAULT_OPTIONS.merge(:user_data_file => :string)
      def launch
        if options[:user_data_file]
          options[:user_data] = File.read(options[:user_data_file])
          options[:base64_encoded] = true
        end
        response = Ec2Instance.launch!(options).instance_data
        additional_report_fields = [
          ['State', 'instanceState name']
        ]
        report('LAUNCHING', additional_report_fields, response)
      end

      desc 'terminate INSTANCE_ID', 'Terminate a running EC2 instance'
      method_options :force => false
      def terminate(instance_id)
        if options[:force] or accept?("Terminate instance #{instance_id}?")
          response = Ec2Instance.new(instance_id).terminate!
          additional_report_fields = [
            ['Previous State', 'previousState name'],
            ['Current State', 'currentState name']
          ]
          report('TERMINATED', additional_report_fields, response)
        end
      end

      private

      def report(title, spec, response)
        spec.unshift(['Instance ID', 'instanceId'])
        super(title, ReportTable.create(spec, [response]))
      end

    end
  end
end
