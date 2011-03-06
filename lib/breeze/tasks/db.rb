module Breeze

  class Db < Veur

    desc 'create NAME', 'Create a new database server'
    method_options CONFIGURATION[:default_db_options]
    def create(name)
      display(rds.servers.create(options.merge(:id => name)))
    end

    desc 'destroy NAME', 'Destroy a database server'
    def destroy(name)
      db = rds.servers.get(name)
      db.destroy(nil)
      db.reload
      display(db)
    end

    private

    def display(db)
      puts "DB State: #{db.state}"
    end

  end
end
