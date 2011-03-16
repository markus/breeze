require 'thor'

module Breeze
  class Initializer < Thor

    include Thor::Actions

    desc 'init [SERVER_PROFILE]', 'described in bin/breeze'
    def init(profile='rails_and_image_magick')
      raise(ArgumentError, "*#{profile}* is not supported") unless profile_exists?(profile)
      copy_file('Thorfile')
      copy_file('user_data.sh', "#{config_dir}/user_data.sh")
      directories('shared', profile_path(profile))
      chmod_600('Thorfile', "#{config_dir}/scripts/credentials.sh")
    end

    private

    def profile_exists?(profile)
      File.directory?("#{self.class.source_root}/#{profile_path(profile)}")
    end

    def directories(*dirs)
      dirs.each{ |dir| directory(dir, config_dir) }
    end

    def chmod_600(*files)
      files.each{ |file| chmod(file, 0600) }
    end

    def config_dir      ; "config/breeze" ; end
    def profile_path(p) ; "profiles/#{p}" ; end

    def self.source_root
      File.join(File.dirname(__FILE__), '..', 'templates')
    end

  end
end
