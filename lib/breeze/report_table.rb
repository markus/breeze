module Breeze

  # Takes a report specification and a query result and produces a report
  # table. The specification is an array containing one array for each
  # column. Each column has a title and a key that may access nested hashes.
  # See ResponseHash to learn how the nested access works.
  class ReportTable

    def self.create(spec, result)
      new(spec, result).to_output_array
    end

    def initialize(spec, result)
      @spec = spec
      result = [result] unless result.is_a?(Array)
      @result = result.map{ |h| ResponseHash.new(h) }
    end

    def to_output_array
      @output_array ||= create_array
    end

    private

    def create_array
      arr = []
      arr << @spec.map{ |attribute| attribute[0] }
      @result.each do |row|
        arr << @spec.map{ |attribute| row.string(attribute[1]) }
      end
      return arr
    end

  end
end
