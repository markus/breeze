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
        ['Name or Location', 'Image ID', 'Owner', 'Image Type', 'Public'],
        fog.images.all('Owner' => Breeze::CONFIGURATION[:image_owner]).map{ |i|
          [i.name||i.location, i.id, i.owner_id, i.full_type, i.is_public]
        }
    end

    desc :servers, 'Describe server instances'
    def servers
      report "SERVER INSTANCES",
        ['Name', 'Instance ID', 'IP Address', 'Image ID', 'Instance Type', 'Availability Zone', 'State'],
        fog.servers.map { |i|
          [i.name, i.id, i.ip_address, i.image_id, i.flavor_id, i.availability_zone, i.state]
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

    desc :dns_zones, 'Describe DNS zones'
    def dns_zones
      zones = dns.zones
      zones.each(&:reload) # necessary in order to get nameservers
      report "DNS ZONES",
        ['Domain', 'Zone ID', 'Name servers'],
        zones.map{ |z| [z.domain, z.id, z.nameservers.join(', ')] }
    end

    desc 'dns_records ZONE_ID', 'List all DNS records for the given zone'
    def dns_records(zone_id)
      zone = dns.zones.get(zone_id)
      report "DNS RECORDS FOR #{zone.domain}",
        ['Name', 'Type', 'TTL', 'Value', 'Status', 'Record ID'],
        zone.records.map{ |r| [r.name, r.type, r.ttl, r.ip, r.status, r.id] }
    end

  end
end
