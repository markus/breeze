require 'breeze/tasks/server'

module Breeze

  class App < Server

    desc 'start PUBLIC_SERVER_NAME', 'Start a new app with web server and db'
    method_options db: true, db_server_name: :string, db_name: :string, db_to_clone: :string,
      elasticache: true, cache_cluster_name: :string,
      elastic_ip: true, dns_ttl: 60,
      elb_name: :string, elb_cname: true,
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
      if options[:elb_name]
        create_elb_and_app_servers(public_server_name, options)
      else
        create_app_server_with_elastic_ip(public_server_name, options)
      end
    end

    desc 'stop PUBLIC_SERVER_NAME', 'Destroy web server and db'
    method_options :force => false
    def stop(public_server_name)
      dbs_to_destroy = []
      cache_clusters_to_destroy = []
      elb_to_destroy = nil
      active_servers(public_server_name).each do |server|
        server.addresses.each do |address|
          thor("server:address:release #{address.public_ip}")
        end
        dbs_to_destroy << server.breeze_data['db']
        cache_clusters_to_destroy << server.breeze_data['cache']
        elb_to_destroy ||= server.breeze_data['elb']
        thor("server:destroy #{server.id}")
      end
      dbs_to_destroy.uniq.compact.each do |db_name|
        thor("db:destroy #{db_name}")
      end
      cache_clusters_to_destroy.uniq.compact.each do |cache_cluster_name|
        thor("elasticache:destroy #{cache_cluster_name}")
      end
      if elb_to_destroy
        elb_cname_record = find_zone_recursively(public_server_name).records.detect{ |r| r.name == "#{public_server_name}." and r.type == 'CNAME' }
        if elb_cname_record
          thor("elb:destroy #{elb_to_destroy} #{public_server_name} #{zone_id(public_server_name)}")
        else
          thor("elb:destroy #{elb_to_destroy}")
        end
      else
        thor("dns:record:destroy #{zone_id(public_server_name)} #{public_server_name}. A")
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
    method_options db_server_name: :string, cache_cluster_name: :string, elb_name: :string, deploy_branch: :string
    def deploy(public_server_name)
      if options[:elb_name]
        deploy_with_elb(public_server_name, options)
      else
        deploy_with_elastic_ip(public_server_name, options)
      end
    end

    desc 'rollback PUBLIC_SERVER_NAME', 'Rollback a deploy'
    method_options elb_name: :string
    def rollback(public_server_name)
      old_servers = spare_servers(public_server_name)
      raise "no running spare server found for #{public_server_name}" if old_servers.size == 0
      old_servers.each do |old_server|
        unless ip(old_server) # the ip may be temporarily unknown if the old elastic ip has been moved to another instance
          wait_until { old_server.reload; ip(old_server) }
        end
        remote('sudo shutdown -c', :host => ip(old_server))
      end
      new_servers = active_servers(public_server_name)
      new_servers.each do |new_server|
        remote(disable_app_command, :host => ip(new_server))
      end
      if options[:elb_name]
        thor("elb:add_instances #{options[:elb_name]} #{old_servers.map(&:id).join(' ')}")
        thor("elb:remove_instances #{options[:elb_name]} #{new_servers.map(&:id).join(' ')}")
      else
        move_addresses(new_servers.first, old_servers.first)
      end
      old_servers.each { |s| s.breeze_state('reactivated') }
      new_servers.each { |s| s.breeze_state('abandoned_due_to_rollback') }
      if accept?("Ready to destroy the abandoned #{new_servers.size} server(s) now?")
        new_servers.each { |s| s.destroy }
      end
    end

    private

    def deploy_with_elb(public_server_name, options)
      old_servers = active_servers(public_server_name)
      create_app_servers_for_elb(public_server_name, options)
      if accept?("Continue and remove the old servers from the ELB?")
        thor("elb:remove_instances #{options[:elb_name]} #{old_servers.map(&:id).join(' ')}")
        old_servers.each do |old_server|
          remote("nohup sudo shutdown -h +#{CONFIGURATION[:rollback_window]} > /dev/null 2>&1 &", :host => ip(old_server))
          old_server.spare_for_rollback!
        end
      end
    end

    def deploy_with_elastic_ip(public_server_name, options)
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

    def create_elb_and_app_servers(public_server_name, options)
      if options[:elb_cname]
        thor("elb:create #{options[:elb_name]} #{public_server_name} #{zone_id(public_server_name)}")
      else
        thor("elb:create #{options[:elb_name]}")
      end
      create_app_servers_for_elb(public_server_name, options.merge(force: true))
    end

    def create_app_servers_for_elb(public_server_name, options)
      servers = []
      CONFIGURATION[:elb][:instances].each do |instance_conf|
        instance_conf = instance_conf.dup
        instance_conf.delete(:count).times do
          servers << create_server(CONFIGURATION[:default_server_options].merge(instance_conf))
          set_server_tags(servers.last, public_server_name, options)
        end
      end
      deploy_command(servers, public_server_name, options)
      servers.each do |server|
        if force_or_accept?("Ready to add #{ip(server)} to ELB #{options[:elb_name]}?")
          thor("elb:add_instances #{options[:elb_name]} #{server.id}")
        else
          server.destroy
        end
      end
    end

    def create_app_server_with_elastic_ip(public_server_name, options)
      server = create_server
      set_server_tags(server, public_server_name, options)
      if options[:elastic_ip]
        thor("server:address:create #{server.id}")
        server.reload until server.addresses.first
      end
      deploy_command([server], public_server_name, options)
      thor("dns:record:create #{zone_id(public_server_name)} #{public_server_name}. A #{ip(server)} #{options[:dns_ttl]}")
    end

    def set_server_tags(server, public_server_name, options)
      server.breeze_data(name: public_server_name, db: options[:db_server_name], cache: options[:cache_cluster_name], elb: options[:elb_name])
    end

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
        if defined?(ELB_NAME)
          thor("app:deploy \#{PUBLIC_SERVER_NAME} --db-server-name=\#{DB_SERVER_NAME} --cache-cluster-name=\#{CACHE_CLUSTER_NAME} --elb-name=\#{ELB_NAME} --deploy-branch=\#{BRANCH}")
        else
          thor("app:deploy \#{PUBLIC_SERVER_NAME} --db-server-name=\#{DB_SERVER_NAME} --cache-cluster-name=\#{CACHE_CLUSTER_NAME} --deploy-branch=\#{BRANCH}")
        end
      end
      desc 'rollback', 'Rollback the previous deploy'
      def rollback
        if defined?(ELB_NAME)
          thor("app:rollback \#{PUBLIC_SERVER_NAME} --elb-name=\#{ELB_NAME}")
        else
          thor("app:rollback \#{PUBLIC_SERVER_NAME}")
        end
      end
      desc 'disable', 'Copy maintenance.html to public/system/ on active web servers'
      def disable
        thor("app:disable \#{PUBLIC_SERVER_NAME}")
      end
      desc 'enable', 'Remove system/maintenance.html from active web servers'
      def enable
        thor("app:enable \#{PUBLIC_SERVER_NAME}")
      end
      desc 'ssh [INSTANCE_ID]', 'Log in with ssh'
      def ssh(instance_id=nil)
        server = (instance_id ? fog.servers.get(instance_id) : active_servers(PUBLIC_SERVER_NAME)[0])
        log_in_to(server.public_ip_address)
      end
      END_TASKS
    end

  end
end
