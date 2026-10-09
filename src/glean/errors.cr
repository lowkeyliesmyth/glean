module Glean
  # A failed accessor read, retaining the requesting Field key and original cause.
  class AccessorReadError < Exception
    getter field_key : String

    def initialize(@field_key : String, cause : Exception)
      super("Could not read value for Field #{@field_key.inspect}", cause)
    end
  end

  class AccessorWriteError < Exception
    getter field_key : String

    def initialize(@field_key : String, cause : Exception)
      super("Could not write value for Field #{@field_key.inspect}", cause)
    end
  end
end
