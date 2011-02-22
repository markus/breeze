module Breeze
  module Aws

    # The class name is a bit weird, but task names are okay:
    #   aws:describe:instances
    # We want plural nouns here, other namespaces are singular:
    #   aws:instance:launch
    class Describe < Veur

      default_task :all
      desc :all, 'List all AWS resources that the current account can control with breeze'
      def all
        images
        instances
        volumes
      end

      desc :images, 'Describe Amazon Machine Images (AMIs) owned by Breeze::CONFIGURATION[:ami_owners]'
      def images
        table = [['Image ID', 'Owner', 'Name or Location', 'Image Type', 'Public']]
        fog.images.all('Owner' => Breeze::CONFIGURATION[:ami_owners][0]).each do |i|
          type_description = "#{i.type}, #{i.architecture}, #{i.root_device_type}"
          table << [i.id, i.owner_id, i.name||i.location, type_description, i.is_public]
        end
        report('AMAZON MACHINE IMAGES', table)
      end

      desc :instances, 'Describe EC2 server instances'
      def instances
        table = [['Name', 'IP Address', 'Instance ID', 'Image ID', 'Instance Type', 'Availability Zone', 'State']]
        fog.servers.each do |i|
          table << [i.tags['Name'], i.ip_address, i.id, i.image_id, i.flavor_id, i.availability_zone, i.state]
        end
        report("EC2 INSTANCES", table)
      end

      desc :volumes, 'Describe Elastic Block Store (EBS) volumes'
      def volumes
        table = [['Volume ID', 'Size', 'Status', 'Zone', 'Snapshot ID', 'Used by']]
        fog.volumes.each do |v|
          table << [v.id, v.size, v.state, v.availability_zone, v.snapshot_id, v.server_id]
        end
        report("EBS VOLUMES", table)
      end

    end
  end
end
