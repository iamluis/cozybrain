# Adapter::Base is the template every concrete adapter inherits from. It
# enforces the three-step protocol on every call:
#
#   1. assert input shape  (port-level contract, paired with Dispatcher)
#   2. _perform            (the adapter's actual work — concrete subclass)
#   3. assert output shape (port-level contract, paired with Dispatcher)
#
# Concrete adapters override two class methods only: .port_module and
# ._perform. Everything else is bookkeeping handled here.
module Adapter
  class Base
    class << self
      def call(input)
        Runtime::Assert.invariant!(input.is_a?(Hash), "#{name}: input must be a Hash, got #{input.class}")

        port_module.assert_input!(input)
        output = _perform(input.deep_dup)

        Runtime::Assert.invariant!(output.is_a?(Hash), "#{name}: _perform must return a Hash, got #{output.class}")
        port_module.assert_output!(output)

        output
      end

      def port_module
        raise NotImplementedError, "#{name} must override .port_module"
      end

      def _perform(_input)
        raise NotImplementedError, "#{name} must override ._perform"
      end
    end
  end
end
