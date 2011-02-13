require 'breeze/aws/aws_proxy'

module Breeze
  module Aws
    module Connection
      private
      def aws
        @aws_proxy ||= AwsProxy.new
      end
    end
  end
end
