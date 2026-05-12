require "test_helper"

class Runtime::AssertTest < ActiveSupport::TestCase
  test "invariant! returns silently when condition is true" do
    assert_nil Runtime::Assert.invariant!(true, "should not raise")
  end

  test "invariant! raises AssertionError when condition is false" do
    err = assert_raises(Runtime::AssertionError) do
      Runtime::Assert.invariant!(false, "explicit message")
    end
    assert_equal "explicit message", err.message
  end

  test "shape! accepts a Hash matching the expected schema with string keys" do
    assert_nothing_raised do
      Runtime::Assert.shape!({ "a" => 1, "b" => "x" }, { "a" => Integer, "b" => String }, where: "test")
    end
  end

  test "shape! accepts symbol keys interchangeably with string keys" do
    assert_nothing_raised do
      Runtime::Assert.shape!({ a: 1, b: "x" }, { "a" => Integer, "b" => String }, where: "test")
    end
  end

  test "shape! raises when value is not a Hash" do
    assert_raises(Runtime::AssertionError) do
      Runtime::Assert.shape!("not a hash", { "a" => Integer }, where: "test")
    end
  end

  test "shape! raises when an expected key is missing" do
    err = assert_raises(Runtime::AssertionError) do
      Runtime::Assert.shape!({ "a" => 1 }, { "a" => Integer, "b" => String }, where: "Port::X input")
    end
    assert_match(/missing key "b"/, err.message)
    assert_match(/Port::X input/,    err.message)
  end

  test "shape! raises when a key has the wrong type" do
    err = assert_raises(Runtime::AssertionError) do
      Runtime::Assert.shape!({ "a" => "not int" }, { "a" => Integer }, where: "test")
    end
    assert_match(/expected Integer/, err.message)
  end
end
