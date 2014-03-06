require 'breeze/tasks/server'

module Breeze

  class App < Server

    desc 'start PUBLIC_SERVER_NAME', 'Start a new app with web server and db'
    method_options db: true, db_server_name: :string, db_name: :string, db_to_clone: :string,
      elasticache: true, cache_cluster_name: :string,
      elastic_ip: true, dns_ttl: 60,
      deploy_branch: :string
    def start(public_server_name)
      if options[:db]
        raise '--db-server-name is required unless --no-db is given.' if options[:db_server_name].nil?
        if options[:db_to_clone]
          thor("db:clone #{options[:db_to_clone]} #{options[:db_server_name]}")
        else
          thor("db:create #{options[:db_server_name]} #{options[:db_name]}")
        end
      end
      if options[:elasticache]
        raise '--cache-cluster-name is required unless --no-elasticache is given.' if options[:cache_cluster_name].nil?
        thor("elasticache:create #{options[:cache_cluster_name]}")
      end
      server = create_server
      server.breeze_data(name: public_server_name, db: options[:db_server_name], cache: options[:cache_cluster_name])
      if options[:elastic_ip]
        thor("server:address:create #{server.id}")
        server.reload until server.addresses.first
      end
      deploy_command([server], public_server_name, options)
      thor("dns:record:create #{zone_id(public_server_name)} #{public_server_name}. A #{ip(server)} #{options[:dns_ttl]}")
    end

    desc 'stop PUBLIC_SERVER_NAME', 'Destroy web server and db'
    method_options :force => false
    def stop(public_server_name)
      dbs_to_destroy = []
      cache_clusters_to_destroy = []
      active_servers(public_server_name).each do |server|
        server.addresses.each do |address|
          thor("server:address:release #{address.public_ip}")
        end
        thor("dns:record:destroy #{zone_id(public_server_name)} #{public_server_name}. A")
        dbs_to_destroy << server.breeze_data['db']
        cache_clusters_to_destroy << server.breeze_data['cache']
        thor("server:destroy #{server.id}")
      end
      dbs_to_destroy.uniq.compact.each do |db_name|
        thor("db:destroy #{db_name}")
      end
      cache_clusters_to_destroy.uniq.compact.each do |cache_cluster_name|
        thor("elasticache:destroy #{cache_cluster_name}")
      end
    end

    desc 'disable PUBLIC_SERVER_NAME', 'Upload system/maintenance.html to web servers'
    def disable(public_server_name)
      on_each_server(disable_app_command, public_server_name)
    end

    desc 'enable PUBLIC_SERVER_NAME', 'Remove system/maintenance.html from web servers'
    def enable(public_server_name)
      on_each_server(enable_app_command, public_server_name)
    end

    desc 'deploy PUBLIC_SERVER_NAME', 'Deploy a new version by replacing old servers with new ones'
    method_options db_server_name: :string, cache_cluster_name: :string, deploy_branch: :string
    def deploy(public_server_name)
      old_server = active_servers(public_server_name).first
      new_server = create_server
      new_server.breeze_data(name: public_server_name, db: options[:db_server_name], cache: options[:cache_cluster_name])
      deploy_command([new_server], public_server_name, options)
      puts("The new server should soon be available at: #{ip(new_server)}")
      if ask("Ready to continue and move the elastic_ip for #{public_server_name} to the new server? [YES/rollback] >") =~ /r|n/i
        new_server.destroy
      elsif old_server
        remote("nohup sudo shutdown -h +#{CONFIGURATION[:rollback_window]} > /dev/null 2>&1 &", :host => ip(old_server))
        old_server.spare_for_rollback!
        move_addresses(old_server, new_server)
      else
        puts('ERROR: Cannot move the IP because the current active server was not found.')
        puts("Move it manually with: thor server:address:associate [IP] #{new_server.id}")
        puts("or create a new elastic IP with: thor server:address:create #{new_server.id}")
      end
    end

    desc 'rollback PUBLIC_SERVER_NAME', 'Rollback a deploy'
    def rollback(public_server_name)
      old_server = spare_servers(public_server_name).first
      raise "no running spare server found for #{public_server_name}" unless old_server
      if ip(old_server)
        temp_ip = nil
      else
        puts("Old server does not have a public ip. Allocating a temporary address:")
        thor("server:address:create #{old_server.id}")
        old_server.reload until old_server.addresses.first
        temp_ip = ip(old_server)
      end
      remote('sudo shutdown -c', :host => ip(old_server))
      new_server = active_servers(public_server_name).first
      remote(disable_app_command, :host => ip(new_server))
      thor("server:address:release #{temp_ip} --force") if temp_ip
      move_addresses(new_server, old_server)
      old_server.breeze_state('reactivated')
      new_server.breeze_state('abandoned_due_to_rollback')
      if accept?('Ready to destroy the abandoned server now?')
        new_server.destroy
      end
    end

    private

    def move_addresses(from_server, to_server)
      from_server.addresses.each do |address|
        thor("server:address:associate #{address.public_ip} #{to_server.id}")
      end
    end

    def running_servers(public_server_name)
      fog.servers.select{ |s| s.ready? and s.name == public_server_name }
    end

    def spare_servers(public_server_name)
      running_servers(public_server_name).select{ |s| s.spare_for_rollback? }
    end

    def active_servers(public_server_name)
      running_servers(public_server_name).select{ |s| not s.spare_for_rollback? }
    end

    def on_each_server(command, public_server_name)
      active_servers(public_server_name).each do |server|
        remote(command, :host => ip(server))
      end
    end

    def disable_app_command
      file = "#{CONFIGURATION[:app_path]}/config/breeze/maintenance.html"
      dir = "#{CONFIGURATION[:app_path]}/public/system"
      "sudo mkdir -p #{dir} && sudo cp #{file} #{dir}"
    end

    def enable_app_command
      "sudo rm #{CONFIGURATION[:app_path]}/public/system/maintenance.html"
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

    def log_in_to(server)
      system("#{CONFIGURATION[:ssh][:ssh_command]} #{CONFIGURATION[:ssh][:ssh_user]}@#{server}")
    end

    # Don't know how to include or inherit thor tasks and descriptions.
    # These may be included in Staging and Production.
    def self.inherited(c)
      c.class_eval <<-END_TASKS
      desc 'deploy', 'Deploy a new version by replacing old servers with new ones'
      def deploy
        thor("app:deploy \#{PUBLIC_SERVER_NAME} --db-server-name=\#{DB_SERVER_NAME} --cache-cluster-name=\#{CACHE_CLUSTER_NAME} --deploy-branch=\#{BRANCH}")
      end
      desc 'rollback', 'Rollback the previous deploy'
      def rollback
        thor("app:rollback \#{PUBLIC_SERVER_NAME}")
      end
      desc 'disable', 'Copy maintenance.html to public/system/ on active web servers'
      def disable
        thor("app:disable \#{PUBLIC_SERVER_NAME}")
      end
      desc 'enable', 'Remove system/maintenance.html from active web servers'
      def enable
        thor("app:enable \#{PUBLIC_SERVER_NAME}")
      end
      desc 'ssh', 'Log in with ssh'
      def ssh
        log_in_to(PUBLIC_SERVER_NAME)
      end
      END_TASKS
    end

  end
end
