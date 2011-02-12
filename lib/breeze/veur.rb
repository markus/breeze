module Breeze

  # Thor is also known as Veur. Veur means "guard of the shrine"
  # (possibly) according to Wikipedia.
  class Veur < Thor

    include Thor::Actions

    private

    def accept?(question)
      ! (ask("#{question} [YES/no] >") =~ /n/i)
    end

    def report(title, table)
      table = capture_table(table)
      title = "=== #{title} "
      title << "=" * [(table.lines.max{|s| s.size }.size - title.size), 3].max
      puts title
      puts table
    end

    def capture_table(table)
      return 'none' if table.size == 1 # the first row is for column titles
      $stdout = StringIO.new  # capture output in order to adjust title width
      print_table(table)
      output = $stdout
      $stdout = STDOUT        # restore normal output
      return output.string
    end

  end
end
