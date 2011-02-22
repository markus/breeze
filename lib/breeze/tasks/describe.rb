module Breeze

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
      report 'AMAZON MACHINE IMAGES',
        ['Image ID', 'Owner', 'Name or Location', 'Image Type', 'Public'],
        fog.images.all('Owner' => Breeze::CONFIGURATION[:ami_owners][0]).map{ |i|
          type_description = "#{i.type}, #{i.architecture}, #{i.root_device_type}"
          [i.id, i.owner_id, i.name||i.location, type_description, i.is_public]
        }
    end

    desc :instances, 'Describe EC2 server instances'
    def instances
      report "EC2 INSTANCES",
        ['Name', 'IP Address', 'Instance ID', 'Image ID', 'Instance Type', 'Availability Zone', 'State'],
        fog.servers.map { |i|
          [i.tags['Name'], i.ip_address, i.id, i.image_id, i.flavor_id, i.availability_zone, i.state]
        }
    end

    desc :volumes, 'Describe Elastic Block Store (EBS) volumes'
    def volumes
      report "EBS VOLUMES",
        ['Volume ID', 'Size', 'Status', 'Zone', 'Snapshot ID', 'Used by'],
        fog.volumes.map { |v|
          [v.id, v.size, v.state, v.availability_zone, v.snapshot_id, v.server_id]
        }
    end

  end
end
