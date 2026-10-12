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

  # Explains why a Field draft was rejected.
  #
  # Validators _return_ this value rather than raising it since it's intentionally not an exception.
  struct ValidationError
    getter message : String

    def initialize(@message : String)
    end
  end
end
