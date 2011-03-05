module Breeze
  module Dns

    class Zone < Veur

      desc 'create DOMAIN', 'Create a new DNS zone'
      def create(domain)
        zone = dns.zones.create(:domain => domain)
        puts "Zone ID: #{zone.id}"
        puts "Change info: #{zone.change_info}"
        puts "Name servers: #{zone.nameservers}"
      end

      desc 'destroy ZONE_ID', 'Destroy a DNS zone'
      def destroy(zone_id)
        zone = dns.zones.get(zone_id)
        if accept?("Destroy DNS zone and records for #{zone.domain}?")
          zone.records.each(&:destroy)
          zone.destroy
        end
      end

      private

      def get_zone(id)
        dns.zones.get(id)
      end

    end

    # This stuff is crazy. It should be deleted as soon as Route 53 gets a web interface.
    class Record < Zone

      desc 'create ZONE_ID NAME TYPE IP', 'Create a new DNS record'
      def create(zone_id, name, type, ip)
        record = get_zone(zone_id).records.create(:name => name, :type => type, :ip => ip)
        puts "Record ID: #{record.id}"
        puts "Status: #{record.status}"
      end

      desc 'destroy ZONE_ID NAME [TYPE] [IP]', 'Destroy a DNS record'
      def destroy(zone_id, name, type=nil, ip=nil)
        records = get_zone(zone_id).records.select{ |r| r.name == name && (type.nil? || r.type == type) && (ip.nil? || r.ip == ip) }
        if accept?("Destroy #{records.size} record#{records.size == 1 ? '' : 's'}?")
          records.each(&:destroy)
        end
      end

    end
  end
end
