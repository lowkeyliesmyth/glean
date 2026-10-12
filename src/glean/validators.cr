module Glean
  module Validators
    # Accepts any string and returns correction feedback if the string is empty.
    def self.not_empty : Proc(String, ValidationError?)
      ->(value : String) {
        ValidationError.new("input can't be empty") if value.empty?
      }
    end

    # Accepts strings that exactly (case-sensitive) match the supplied **values**.
    #
    # An empty list matches nothing.
    def self.one_of(values : Enumerable(String)) : Proc(String, ValidationError?)
      allowed = values.to_a.dup

      ->(value : String) {
        unless allowed.includes?(value)
          ValidationError.new("invalid option: #{value}")
        end
      }
    end
  end
end
