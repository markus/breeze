module Breeze

  class Db < Veur

    desc 'create SERVER_NAME [DB_NAME]', 'Create a new database server'
    method_options CONFIGURATION[:default_db_options]
    def create(name, db_name=nil)
      options.update(:id => name, :db_name => db_name)
      # puts "DB options: #{options}"
      rds.servers.create(options)
    end

    desc 'destroy NAME', 'Destroy a database server'
    method_options :force => false
    def destroy(name)
      db = rds.servers.get(name)
      if not %w(available failed storage-full incompatible-parameters incompatible-restore).include?(db.state)
        puts "ERROR: cannot destroy db while state is #{db.state}!"
      elsif force_or_accept?("Destroy DB #{name}?")
        db.destroy(nil)
        db.reload
      end
    end

    desc 'clone OLD_DB NEW_DB', 'Create a new db server using the latest backup of OLD_DB.'
    def clone(old_db, new_db)
      rds.restore_db_instance_to_point_in_time(old_db, new_db, 'UseLatestRestorableTime' => true)
    end

  end
end
