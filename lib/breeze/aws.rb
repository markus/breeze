require 'breeze/aws/aws_proxy'

module Breeze
  module Aws
    def self.connection
      @connection ||= AwsProxy.new
    end
  end
end

require 'breeze/aws/aws_veur'
require 'breeze/aws/ec2_instance'

require 'breeze/aws/tasks/describe'
