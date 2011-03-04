module Breeze

  class List < Veur

    default_task :all
    desc :all, 'List all AWS resources that the current account can control with breeze'
    def all
      images
      servers
      volumes
    end

    desc :images, 'Describe machine images owned by Breeze::CONFIGURATION[:image_owner]'
    def images
      report 'MACHINE IMAGES',
        ['Image ID', 'Owner', 'Name or Location', 'Image Type', 'Public'],
        fog.images.all('Owner' => Breeze::CONFIGURATION[:image_owner]).map{ |i|
          [i.id, i.owner_id, i.name||i.location, i.full_type, i.is_public]
        }
    end

    desc :servers, 'Describe server instances'
    def servers
      report "SERVER INSTANCES",
        ['Name', 'IP Address', 'Instance ID', 'Image ID', 'Instance Type', 'Availability Zone', 'State'],
        fog.servers.map { |i|
          [i.name, i.ip_address, i.id, i.image_id, i.flavor_id, i.availability_zone, i.state]
        }
    end

    desc :volumes, 'Describe block store volumes (EBS)'
    def volumes
      report "VOLUMES",
        ['Volume ID', 'Size', 'Status', 'Zone', 'Snapshot ID', 'Used by'],
        fog.volumes.map { |v|
          [v.id, v.size, v.state, v.availability_zone, v.snapshot_id, v.server_id]
        }
    end

  end
end
