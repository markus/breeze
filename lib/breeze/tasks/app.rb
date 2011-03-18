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
      thor("server:address:create #{server.id}") if options[:elastic_ip]
      thor("dns:record:create #{zone_id(public_server_name)} #{public_server_name}. A #{ip(server)} #{options[:dns_ttl]}")
      thor("server:tag:create #{server.id} breeze-data '#{server.breeze_data(:name => public_server_name, :db => db_server_name)}'")
    end

    desc 'stop PUBLIC_SERVER_NAME', 'Destroy web server and db'
    method_options :force => false
    def stop(public_server_name)
      dbs_to_destroy = []
      active_servers(public_server_name).each do |server|
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

    desc 'disable PUBLIC_SERVER_NAME', 'Upload system/maintenance.html to web servers'
    def disable(public_server_name)
      on_each_server("cd #{CONFIGURATION[:app_path]} && cp config/breeze/maintenance.html public/system/", public_server_name)
    end

    desc 'enable PUBLIC_SERVER_NAME', 'Remove system/maintenance.html from web servers'
    def enable(public_server_name)
      on_each_server("rm #{CONFIGURATION[:app_path]}/public/system/maintenance.html", public_server_name)
    end

    private

    def active_servers(public_server_name)
      fog.servers.select{ |s| s.name == public_server_name and not s.spare_for_rollback? }
    end

    def on_each_server(command, public_server_name)
      active_servers(public_server_name).each do |server|
        remote(command, :host => ip(server))
      end
    end

    def db_endpoint(db_server_name)
      db = rds.servers.get(db_server_name)
      return nil unless db
      unless db.ready?
        print('Waiting for the db')
        wait_until { db.reload; db.ready? }
      end
      db.endpoint['Address']
    end

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
