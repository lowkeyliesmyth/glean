require "../spec_helper"

describe Glean::ValidationError do
  it "preserves message without trimming it" do
    error = Glean::ValidationError.new("  enter a name  ")

    error.message.should eq("  enter a name  ")
  end
end

describe Glean::Validators do
  describe ".not_empty" do
    it "accepts nonempty input" do
      validator = Glean::Validators.not_empty

      validator.call("Kiff").should be_nil
    end

    it "considers whitespace as not empty and doesn't trim it" do
      validator = Glean::Validators.not_empty

      validator.call(" ").should be_nil
      validator.call("\t").should be_nil
    end

    it "returns correction feedback for empty input" do
      validator = Glean::Validators.not_empty

      rejected = validator.call("")

      rejected.should be_a(Glean::ValidationError)
      rejected.not_nil!.message.should eq("input can't be empty") # ameba:disable Lint/NotNil
    end

    it "accepts corrected input after rejecting empty string" do
      validator = Glean::Validators.not_empty

      validator.call("").should be_a(Glean::ValidationError)
      validator.call("Kiff").should be_nil
    end
  end

  describe ".one_of" do
    it "accepts an allowed value" do
      validator = Glean::Validators.one_of(["yes", "no"])

      validator.call("yes").should be_nil
      validator.call("no").should be_nil
    end

    it "returns corrections for an invalid value" do
      validator = Glean::Validators.one_of(["yes", "no"])

      rejected = validator.call("maybe")

      rejected.should be_a(Glean::ValidationError)
      rejected.not_nil!.message.should eq("invalid option: maybe") # ameba:disable Lint/NotNil
    end

    it "rejects mismatched case and whitespace" do
      validator = Glean::Validators.one_of(["yes", "no"])

      validator.call("YES").should be_a(Glean::ValidationError)
      validator.call("no ").should be_a(Glean::ValidationError)
    end

    it "accepts an empty string when explicitly allowed" do
      validator = Glean::Validators.one_of(["", "not_empty"])
      validator.call("").should be_nil
    end

    it "rejects input when the allowed list is empty" do
      validator = Glean::Validators.one_of([] of String)

      validator.call("").should be_a(Glean::ValidationError)
      validator.call("yup").should be_a(Glean::ValidationError)
    end

    it "keeps its allowed values when the source array changes afterwards" do
      values = ["yes", "no"]
      validator = Glean::Validators.one_of(values)

      values.clear
      values.push("maybe")

      validator.call("yes").should be_nil
      validator.call("no").should be_nil
      validator.call("maybe").should be_a(Glean::ValidationError)
    end

    it "gracefully continues when dupes are in the allowed list" do
      validator = Glean::Validators.one_of(["yes", "yes", "no"])

      validator.call("yes").should be_nil
      validator.call("maybe").should be_a(Glean::ValidationError)
    end
  end
end
