module Breeze
  module Aws

    # A subclass of Thor with helpers for AWS tasks.
    class AwsVeur < Veur

      # shorten the task names
      def self.inherited(c)
        c.class_eval do
          namespace Thor::Util.namespace_from_thor_class(c).sub('breeze:aws', 'aws')
        end
      end

      private

      def aws
        Aws.connection
      end

    end
  end
end
