require 'breeze/veur'
require 'breeze/aws/connection'

module Breeze
  module Aws

    # A subclass of Thor with helpers for AWS tasks.
    class AwsVeur < Veur

      include Connection

      # shorten the task names
      def self.inherited(c)
        c.class_eval do
          namespace Thor::Util.namespace_from_thor_class(c).sub('breeze:aws', 'aws')
        end
      end

      private

      # Convert the keys to symbols for the amazon-ec2 gem.
      def options
        @options_with_symbolized_keys ||= {}.tap{ |h| super.each{ |k,v| h[k.to_sym] = v } }
      end
    end
  end
end
