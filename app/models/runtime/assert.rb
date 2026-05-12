# Runtime::Assert is the TigerStyle assertion harness used throughout the
# integration spine. Two helpers:
#
#   - invariant!(condition, message)   — raise if condition is false
#   - shape!(value, expected, where:)  — raise unless value is a Hash whose
#                                         keys/types match `expected`
#
# Why a custom helper rather than Ruby's built-in `raise`:
# the helpers give every assertion a consistent error class, a uniform
# message format ("where: detail"), and a single place to flip behavior
# (e.g., log-only vs raise) if we ever need it.
module Runtime
  module Assert
    module_function

    def invariant!(condition, message)
      return if condition
      raise AssertionError, message
    end

    def shape!(value, expected, where:)
      invariant!(value.is_a?(Hash), "#{where}: expected Hash, got #{value.class}")

      expected.each do |key, type|
        actual = value[key.to_s]
        actual = value[key.to_sym] if actual.nil?
        invariant!(!actual.nil?, "#{where}: missing key #{key.inspect}")
        invariant!(actual.is_a?(type), "#{where}: key #{key.inspect} expected #{type}, got #{actual.class}")
      end
    end
  end
end
