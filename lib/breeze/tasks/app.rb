require 'breeze/tasks/server'

module Breeze

  class App < Server

    desc 'start PUBLIC_SERVER_NAME [DB_SERVER_NAME] [DB_NAME]', 'Start a new app with web server and db'
    method_options :db => true, :db_to_clone => :string, :elastic_ip => true, :dns_ttl => 60
    def start(public_server_name, db_server_name=nil, db_name=nil)
      if options[:db]
        raise 'DB_SERVER_NAME is required unless --no-db is given.' if db_server_name.nil?
        if options[:db_to_clone]
          thor("db:clone #{options[:db_to_clone]} #{db_server_name}")
        else
          thor("db:create #{db_server_name} #{db_name}")
        end
      end
      server = create_server
      thor("server:address:create #{server.id}")
      thor("server:tag:create #{server.id} breeze-data '#{server.breeze_data(:name => public_server_name, :db => db_server_name)}'")
      thor("dns:record:create #{zone_id(public_server_name)} #{public_server_name}. A #{ip(server)} #{options[:dns_ttl]}")
    end

    desc 'stop PUBLIC_SERVER_NAME', 'Destroy web server and db'
    method_options :force => false
    def stop(public_server_name)
      dbs_to_destroy = []
      fog.servers.select{ |s| s.name == public_server_name }.each do |server|
        server.addresses.each do |address|
          thor("server:address:release #{address.public_ip}")
        end
        thor("dns:record:destroy #{zone_id(public_server_name)} #{public_server_name}. A")
        dbs_to_destroy << server.breeze_data['db']
        thor("server:destroy #{server.id}")
      end
      dbs_to_destroy.uniq.compact.each do |db_name|
        thor("db:destroy #{db_name}")
      end
    end

    private

    def ip(server)
      address = server.addresses.first
      address ? address.public_ip : server.public_ip_address
    end

    def zone_id(name)
      find_zone_recursively(name).id or raise("CANNOT FIND DNS ZONE FOR #{name}")
    end

    def find_zone_recursively(name)
      return nil unless name.include?('.')
      dns.zones.detect{ |z| z.domain == "#{name}." } or find_zone_recursively(name.sub(/[^.]*\./, ''))
    end

    def thor(task)
      super(task + (options[:force] ? ' --force' : ''))
    end

  end
end
