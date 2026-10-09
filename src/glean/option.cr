module Glean
  # Immutable label and value for choice type Field display presentation state.
  #
  # Equality and hashing methods include both the labels and the value.
  struct Option(T)
    getter label : String
    getter value : T

    def initialize(@label : String, @value : T)
    end

    def_equals_and_hash @label, @value

    # Create one choice option for each input **value**, in input order.
    #
    # Generates each value's label from its `to_s` result.
    def self.from_values(values : Enumerable(T)) : Array(Option(T))
      values.map { |value| new(value.to_s, value) }
    end
  end
end
