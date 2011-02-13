require 'breeze/version'

module Breeze

  autoload :ResponseHash, 'breeze/response_hash'
  autoload :ReportTable,  'breeze/report_table'

  # get a slice from the CONFIGURATION hash
  def self.conf(*args)
    CONFIGURATION.reject{ |k,v| !args.include?(k) }
  end

end
