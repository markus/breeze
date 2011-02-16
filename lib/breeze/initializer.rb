require 'thor'

module Breeze
  class Initializer < Thor

    include Thor::Actions

    desc 'init [SERVER_PROFILE]', 'described in bin/breeze'
    def init(profile='rails_and_image_magick')
      raise(ArgumentError, "*#{profile}* is not supported") unless profile_exists?(profile)
      copy_file('Thorfile')
      directory('config', "#{config_dir}/config")
      ['user_data.sh', 'script/*.sh', "#{profile_path(profile)}/*"].each do |pattern|
        copy_files(pattern)
      end
    end

    private

    def profile_exists?(profile)
      File.directory?("#{source_root}/#{profile_path(profile)}")
    end

    def copy_files(pattern)
      Dir["#{source_root}/#{pattern}"].each do |path|
        copy_file(path, "#{config_dir}/#{File.basename(path)}")
      end
    end

    def config_dir      ; "config/breeze"         ; end
    def source_root     ; self.class.source_root  ; end
    def profile_path(p) ; "script/profiles/#{p}"  ; end

    def self.source_root
      File.join(File.dirname(__FILE__), '..', 'templates')
    end
  end
end
