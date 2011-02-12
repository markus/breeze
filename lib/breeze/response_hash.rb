module Breeze

  # Provides easy access to nested hashes that may or may not be present.
  class ResponseHash < Hash
    # constructor copied from activesupport
    def initialize(constructor = {})
      if constructor.is_a?(Hash)
        super()
        update(constructor)
      else
        super(constructor)
      end
    end

    # Provides access to nested hashes through a string of keys separated by spaces.
    # Always returns a string even if expected hashes would not be present.
    def string(keys)
      get_nested_value(self, keys.split(' ')).to_s
    end

    # Provides access to nested hashes through a string of keys separated by spaces.
    # Always returns an array even if expected hashes would not be present.
    def array(keys)
      value = get_nested_value(self, keys.split(' '))
      return [] unless value.is_a?(Array)
      value.map{ |h| h.instance_of?(Hash) ? ResponseHash.new(h) : h }
    end

    # Use this if you expect an array with one item.
    # Returns a ResponseHash even if the array would not be present.
    def first_hash(keys)
      ResponseHash.new(array(keys).first)
    end

    private

    # recursive hash accessor
    def get_nested_value(hash, keys)
      return hash unless hash.is_a?(Hash)
      return hash[keys] unless keys.is_a?(Array)
      return get_nested_value(hash[keys.shift], keys)
    end
  end
end
