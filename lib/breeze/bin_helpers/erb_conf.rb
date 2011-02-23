require 'erb'
require 'fileutils'
require 'socket'

module Breeze

  # The idea was stolen from rubber: https://github.com/wr0ngway/rubber
  # but this is a simple implementation with no support for roles and additives.
  class ErbConf

    # Transform and deploy ERB based configuration files to the local file system.
    # This is almost compatible with https://github.com/wr0ngway/rubber/wiki/Configuration
    # but there is no support for @additive and rubber configuration.
    def deploy(force=false)
      Dir['config/breeze/configs/**/*'].each do |path|
        transform_and_deploy(path, force) unless File.directory?(path)
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

    # ERB templates may need cluster_name and host_name
    def cluster_name ; nil                ; end
    def host_name    ; Socket.gethostname ; end
  end
end
