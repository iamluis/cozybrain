# A Runtime::AssertionError signals a programmer error — an invariant that
# the framework relies on has been violated. Unlike StandardError-derived
# domain errors, these should never be silently rescued in production code;
# they crash loudly so the bug surfaces.
module Runtime
  class AssertionError < StandardError; end
end
