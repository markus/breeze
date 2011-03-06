require 'breeze/fog_extensions'

module Breeze

  # Thor is also known as Veur. Veur means "guard of the shrine"
  # (possibly) according to Wikipedia.
  class Veur < Thor

    include Thor::Actions

    # shorten the task names
    def self.inherited(c)
      c.class_eval do
        namespace Thor::Util.namespace_from_thor_class(c).sub('breeze:', '')
      end
    end

    private

    # Thor freezes the options (don't understand why)
    def options
      @unfrozen_options ||= super.dup
    end

    # yes? in thor cannot be accepted with enter
    def accept?(question)
      ! (ask("#{question} [YES/no] >") =~ /n/i)
    end

    # Print out dots while waiting for something.
    # Usage:
    #   print "My task is running..."
    #   wait_until { my_task.completed? }
    def wait_until(message='completed!')
      3.times { dot_and_sleep(1) }
      dot_and_sleep(2) until yield
      puts message
    end

    # a helper for wait_until
    def dot_and_sleep(interval)
      print('.')
      sleep(interval)
    end

    # Print a table with a title and a top border of matching width.
    def report(title, columns, rows)
      table = capture_table([columns] + rows)
      title = "=== #{title} "
      title << "=" * [(table.lines.max{|s| s.size }.size - title.size), 3].max
      puts title
      puts table
    end

    # capture table in order to determine it's width
    def capture_table(table)
      return 'none' if table.size == 1 # the first row is for column titles
      $stdout = StringIO.new  # start capturing the output
      print_table(table.map{ |row| row.map(&:to_s) })
      output = $stdout
      $stdout = STDOUT        # restore normal output
      return output.string
    end

    def fog
      @fog ||= Fog::Compute.new(CONFIGURATION[:cloud_service])
    end

    def dns
      @dns ||= Fog::DNS.new(CONFIGURATION[:cloud_service])
    end

    def rds
      return @rds if @rds
      credentials = CONFIGURATION[:cloud_service].reject{ |k,v| k == :provider }
      credentials[:region] = CONFIGURATION[:db_region]
      @rds = Fog::AWS::RDS.new(credentials)
    end

  end
end
