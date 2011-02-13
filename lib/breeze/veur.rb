module Breeze

  # Thor is also known as Veur. Veur means "guard of the shrine"
  # (possibly) according to Wikipedia.
  class Veur < Thor

    include Thor::Actions

    private

    # Thor freezes the options (don't understand why)
    def options
      @unfrozen_options ||= super.dup
    end

    # yes? in thor cannot be accepted with enter
    def accept?(question)
      ! (ask("#{question} [YES/no] >") =~ /n/i)
    end

    # Print a table with a title and a top border of matching width.
    # The first row must contain column titles, less than 2 rows is not printed.
    def report(title, table)
      table = capture_table(table)
      title = "=== #{title} "
      title << "=" * [(table.lines.max{|s| s.size }.size - title.size), 3].max
      puts title
      puts table
    end

    # capture table in order to determine it's width
    def capture_table(table)
      return 'none' if table.size == 1 # the first row is for column titles
      $stdout = StringIO.new  # start capturing the output
      print_table(table)
      output = $stdout
      $stdout = STDOUT        # restore normal output
      return output.string
    end

  end
end
