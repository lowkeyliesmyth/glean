require "./errors"

module Glean
  # Typed values access shared by embedded storage and application-owned bindings.
  #
  # Accessors don't track initial or default presence, validate drafts, or publish accepted values.
  abstract class Accessor(T)
    # Read the current value, using **field_key** as context for an `AccessorReadError`.
    abstract def read(field_key : String) : T

    # Write **value**, using **field_key** as context for an `AccessorWriteError`.
    #
    # Normal return means the write completed. Must raise on any write failure.
    abstract def write(value : T, field_key : String) : Nil
  end

  # Stores one value of type T.
  #
  # Each instance has its own storage. Mutable objects are stored as references and not copies.
  class EmbeddedAccessor(T) < Accessor(T)
    def initialize(@value : T)
    end

    # Return the stored **field_key**'s value.
    def read(field_key : String) : T
      @value
    end

    # Replace the stored **field_key**'s value with **value**.
    def write(value : T, field_key : String) : Nil
      @value = value
      nil
    end
  end

  # Reads and writes application-owned state through caller-provided procs. Neither callback is actually called during initialization.
  #
  # Each read receives the getter's current value.
  class BoundAccessor(T) < Accessor(T)
    def initialize(@getter : Proc(T), @setter : Proc(T, Nil))
    end

    # Call the `@getter` proc, wrap any exception with the requesting **field_key**.
    def read(field_key : String) : T
      @getter.call
    rescue ex : Exception
      raise AccessorReadError.new(field_key, ex)
    end

    # Call the `@setter` proc with **value**, wrap any exception with the requesting **field_key**.
    #
    # Normal return means the setter completed. Any setter that mutates state before raising can't be rolled back.
    def write(value : T, field_key : String) : Nil
      @setter.call(value)
    rescue ex : Exception
      raise AccessorWriteError.new(field_key, ex)
    end
  end
end
