require 'thor'

module Breeze
  class Initializer < Thor

    include Thor::Actions

    desc 'init [SERVER_PROFILE]', 'described in bin/breeze'
    def init(profile='rails_and_image_magick')
      raise(ArgumentError, "*#{profile}* is not supported") unless profile_exists?(profile)
      copy_file('Thorfile')
      chmod('Thorfile', 0600)
      directory('config', "#{config_dir}/config")
      copy_many_files_to_config('user_data.sh', 'script/*.sh', "#{profile_path(profile)}/*")
      chmod("#{config_dir}/credentials.sh", 0600)
    end

    private

    def profile_exists?(profile)
      File.directory?("#{source_root}/#{profile_path(profile)}")
    end

    def copy_many_files_to_config(*patterns)
      patterns.each do |pattern|
        Dir["#{source_root}/#{pattern}"].each do |path|
          copy_file(path, "#{config_dir}/#{File.basename(path)}")
        end
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
