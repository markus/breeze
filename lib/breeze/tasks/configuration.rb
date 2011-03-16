require 'erb'
require 'fileutils'
require 'socket'

module Breeze

  # The idea was stolen from rubber: https://github.com/wr0ngway/rubber
  # but this is a simple implementation with no support for roles and additives.
  # See https://github.com/wr0ngway/rubber/wiki/Configuration
  class Configuration < Veur

    desc 'deploy_to_localhost',
      'Transform and deploy server configuration files to the local file system based on ERB templates in config/server'
    method_option :force, :default => false, :desc => 'Overwrite and execute @post commands even if files would not change'
    def deploy_to_localhost
      Dir['config/breeze/configs/**/*'].each do |path|
        transform_and_deploy(path, options[:force]) unless File.directory?(path)
      end
    end

    private

    def transform_and_deploy(file, force=false)
      @read_cmd = @write_cmd = @path = @perms = @owner = @group = @post = nil
      transformed = ERB.new(File.read(file)).result(binding)
      original = IO.read(@path||"|#{@read_cmd}") if @path.nil? or File.exist?(@path)
      report_errors(@read_cmd)
      if force or original != transformed
        ensure_directory_and_backup if @path
        open(@path||"|#{@write_cmd}", 'w') { |f| f.write(transformed) }
        report_errors(@write_cmd)
        set_owner_and_permissions if @path
        if @post
          system("set -e; #{@post}")
          report_errors(@post)
        end
      end
    end

    def ensure_directory_and_backup
      if File.exist?(@path)
        FileUtils.cp(@path, "#{@path}.backup", :preserve => true)
      else
        FileUtils.mkdir_p(File.dirname(@path))
      end
    end

    def set_owner_and_permissions
      FileUtils.chmod(@perms, @path) if @perms
      FileUtils.chown(@owner, @group, @path) if @owner || @group
    end

    def report_errors(cmd)
      raise "COMMAND FAILED: #{cmd}" unless $?.nil? || $?.success?
    end

    # a helper for ERB templates
    def host_name
      Socket.gethostname
    end

  end
end
