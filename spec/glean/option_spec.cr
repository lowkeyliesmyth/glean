require "../spec_helper"

record OptionSpecValue, code : Int32, name : String

struct OptionSpecUnlabelable
  def initialize(@cause : Exception)
  end

  def to_s(io : IO) : Nil
    raise @cause
  end
end

describe Glean::Option do
  it "stores a label and typed value" do
    option = Glean::Option(Int32).new("Three", 3)

    option.label.should eq("Three")
    option.value.should eq(3)
  end

  it "support caller-defined value types" do
    value = OptionSpecValue.new(7, "custom")
    option = Glean::Option(OptionSpecValue).new("Custom choice", value)

    option.label.should eq("Custom choice")
    option.value.should eq(value)
  end

  it "compares options by combined label and value" do
    option = Glean::Option(Int32).new("Three", 3)
    equivalent = Glean::Option(Int32).new("Three", 3)

    option.should eq(equivalent)
    option.hash.should eq(equivalent.hash)

    option.should_not eq(Glean::Option(Int32).new("Other label", 3))
    option.should_not eq(Glean::Option(Int32).new("Three", 4))
  end

  describe ".from_values" do
    it "derives labels and preserves order" do
      options = Glean::Option(Int32).from_values([3, 2, 1])

      options.should eq([
        Glean::Option(Int32).new("3", 3),
        Glean::Option(Int32).new("2", 2),
        Glean::Option(Int32).new("1", 1),
      ])
    end

    it "accepts enumerable sources other than just arrays" do
      options = Glean::Option(Int32).from_values(1..3)

      options.map(&.label).should eq(["1", "2", "3"])
      options.map(&.value).should eq([1, 2, 3])
    end

    it "handles an empty source" do
      options = Glean::Option(String).from_values([] of String)

      options.should eq([] of Glean::Option(String))
    end

    it "preserves false, zero, and empty values" do
      Glean::Option(Bool).from_values([false]).should eq([
        Glean::Option(Bool).new("false", false),
      ])
      Glean::Option(Int32).from_values([0]).should eq([
        Glean::Option(Int32).new("0", 0),
      ])
      Glean::Option(String).from_values([""]).should eq([
        Glean::Option(String).new("", ""),
      ])
    end

    it "does not share structure with source or other instances" do
      values = ["first", "second"]
      first = Glean::Option(String).from_values(values)
      second = Glean::Option(String).from_values(values)

      values[0] = "changed"
      values << "third"
      first.clear

      second.should eq([
        Glean::Option(String).new("first", "first"),
        Glean::Option(String).new("second", "second"),
      ])
      values.should eq(["changed", "second", "third"])
    end

    it "preserves repeated values" do
      options = Glean::Option(Int32).from_values([1, 1])

      options.should eq([
        Glean::Option(Int32).new("1", 1),
        Glean::Option(Int32).new("1", 1),
      ])
    end
  end
end
