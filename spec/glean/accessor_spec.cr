require "../spec_helper"

record EmbeddedAccessorSpecValue, code : Int32, name : String

describe Glean::EmbeddedAccessor do
  it "reads and writes through the typed Accessor interface" do
    accessor : Glean::Accessor(String) = Glean::EmbeddedAccessor(String).new("initial")

    # Right now the field_key doesn't actually do anything. We're just setting the interface. Just deal with it, it will matter eventually.
    accessor.read("name").should eq("initial")
    accessor.write("accepted", "name").should be_nil
    accessor.read("name").should eq("accepted")
  end

  it "stores explicit false and zero values" do
    enabled = Glean::EmbeddedAccessor(Bool).new(false)
    count = Glean::EmbeddedAccessor(Int32).new(0)

    enabled.read("enabled").should be_false
    count.read("count").should eq(0)

    enabled.write(true, "enabled")
    enabled.write(false, "enabled")
    count.write(3, "count")
    count.write(0, "count")

    enabled.read("enabled").should be_false
    count.read("count").should eq(0)
  end

  it "preserves explicit empty strings and collections" do
    name = Glean::EmbeddedAccessor(String).new("")
    tags = Glean::EmbeddedAccessor(Array(String)).new([] of String)

    name.read("name").should eq("")
    tags.read("tags").should eq([] of String)

    name.write("William", "name")
    name.write("", "name")
    tags.write(["crystal"], "tags")
    tags.write([] of String, "tags")

    name.read("name").should eq("")
    tags.read("tags").should eq([] of String)
  end

  it "stores nil as a valid typed value" do
    accessor = Glean::EmbeddedAccessor(String?).new(nil)

    accessor.read("nickname").should be_nil
    accessor.write("Bill", "nickname")
    accessor.read("nickname").should eq("Bill")
    accessor.write(nil, "nickname").should be_nil
    accessor.read("nickname").should be_nil
  end

  it "stores caller-provided value types" do
    initial = EmbeddedAccessorSpecValue.new(1, "initial")
    replacement = EmbeddedAccessorSpecValue.new(2, "replacement")
    accessor = Glean::EmbeddedAccessor(EmbeddedAccessorSpecValue).new(initial)

    accessor.read("choice").should eq(initial)
    accessor.write(replacement, "choice")
    accessor.read("choice").should eq(replacement)
  end
end

describe Glean::BoundAccessor do
  it "reads current app state and writes through the typed interface" do
    state = "initial"
    writes = [] of String
    getter = -> { state }
    setter = ->(value : String) {
      writes << value
      state = value
      nil
    }

    accessor : Glean::Accessor(String) = Glean::BoundAccessor(String).new(getter, setter)

    accessor.read("name").should eq("initial")

    state = "changed externally"
    accessor.read("name").should eq("changed externally")

    accessor.write("accepted", "name").should be_nil

    state.should eq("accepted")
    writes.should eq(["accepted"])
    accessor.read("name").should eq("accepted")
  end

  it "doesn't call either proc during construction" do
    reads = 0
    writes = 0
    getter = -> {
      reads += 1
      "current"
    }
    setter = ->(_value : String) {
      writes += 1
      nil
    }
    accessor = Glean::BoundAccessor(String).new(getter, setter)

    reads.should eq(0)
    writes.should eq(0)

    accessor.read("name").should eq("current")
    reads.should eq(1)
    writes.should eq(0)
  end

  it "stores explicit false values" do
    state = false
    getter = -> { state }
    setter = ->(value : Bool) {
      state = value
      nil
    }
    accessor = Glean::BoundAccessor(Bool).new(getter, setter)

    accessor.read("enabled").should be_false
    accessor.write(true, "enabled")
    state.should be_true
    accessor.write(false, "enabled").should be_nil
    state.should be_false
  end

  it "stores explicit zero values" do
    state = 0
    getter = -> { state }
    setter = ->(value : Int32) {
      state = value
      nil
    }

    accessor = Glean::BoundAccessor(Int32).new(getter, setter)

    accessor.read("count").should eq(0)
    accessor.write(3, "count")
    state.should eq(3)
    accessor.write(0, "count")
    state.should eq(0)
  end

  it "stores explicit empty strings" do
    state = ""
    getter = -> { state }
    setter = ->(value : String) {
      state = value
      nil
    }
    accessor = Glean::BoundAccessor(String).new(getter, setter)

    accessor.read("name").should eq("")
    accessor.write("Zed", "name")
    state.should eq("Zed")
    accessor.write("", "name")
    state.should eq("")
  end

  it "stores explicit empty collections" do
    state = [] of String
    getter = -> { state }
    setter = ->(value : Array(String)) {
      state = value
      nil
    }
    accessor = Glean::BoundAccessor(Array(String)).new(getter, setter)

    accessor.read("tags").should eq([] of String)

    replacement = ["crystal"]
    accessor.write(replacement, "tags")
    state.should be(replacement)

    replacement << "forms"
    accessor.read("tags").should eq(["crystal", "forms"])

    accessor.write([] of String, "tags")
    state.should eq([] of String)
  end

  it "stores nil as a valid typed value" do
    state : String? = nil
    getter = -> { state }
    setter = ->(value : String?) {
      state = value
      nil
    }
    accessor = Glean::BoundAccessor(String?).new(getter, setter)

    accessor.read("nickname").should be_nil
    accessor.write("Zed", "nickname")
    state.should eq("Zed")
    accessor.write(nil, "nickname").should be_nil
    state.should be_nil
  end

  it "wraps getter failures with the current Field key and the original cause" do
    cause = Exception.new("app read failed")
    failing = true
    getter = -> {
      raise cause if failing
      "available"
    }
    setter = ->(_value : String) { nil }
    accessor = Glean::BoundAccessor(String).new(getter, setter)

    error = expect_raises(Glean::AccessorReadError) do
      accessor.read("first")
    end

    error.field_key.should eq("first")
    error.cause.should be(cause)

    error = expect_raises(Glean::AccessorReadError) do
      accessor.read("second")
    end

    error.field_key.should eq("second")
    error.cause.should be(cause)

    failing = false
    accessor.read("second").should eq("available")
  end

  it "raises on a failed setter without retrying and permits a later write" do
    state = "initial"
    calls = 0
    failing = true
    cause = Exception.new("application write failed")
    getter = -> { state }
    setter = ->(value : String) {
      calls += 1
      raise cause if failing
      state = value
      nil
    }
    accessor = Glean::BoundAccessor(String).new(getter, setter)

    error = expect_raises(Glean::AccessorWriteError) do
      accessor.write("candidate", "name")
    end

    error.field_key.should eq("name")
    error.cause.should be(cause)
    calls.should eq(1)
    state.should eq("initial")
    accessor.read("name").should eq("initial")

    failing = false
    accessor.write("accepted", "name").should be_nil

    calls.should eq(2)
    state.should eq("accepted")
  end
end
