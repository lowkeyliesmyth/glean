require "../spec_helper"

describe Glean::AccessorReadError do
  it "retains the requesting Field key and original cause" do
    cause = Exception.new("getter failed")
    error = Glean::AccessorReadError.new("name", cause)

    error.field_key.should eq("name")
    error.cause.should be(cause)
    error.message.should eq("Could not read value for Field \"name\"")
  end

  it "keeps empty Field key context without requiring key validation" do
    cause = Exception.new
    error = Glean::AccessorReadError.new("", cause)

    error.field_key.should eq("")
    error.cause.should be(cause)
  end
end

describe Glean::AccessorWriteError do
  it "retains the requesting Field key and original cause" do
    cause = Exception.new("getter failed")
    error = Glean::AccessorWriteError.new("enabled", cause)

    error.field_key.should eq("enabled")
    error.cause.should be(cause)
    error.message.should eq("Could not write value for Field \"enabled\"")
  end

  it "keeps empty Field key context without requiring key validation" do
    cause = Exception.new
    error = Glean::AccessorWriteError.new("", cause)

    error.field_key.should eq("")
    error.cause.should be(cause)
  end
end
