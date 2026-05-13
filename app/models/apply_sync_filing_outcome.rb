# Applies the terminal outcome of a sync_filing Operation: stamps the
# Filing's synced_at on success; leaves it untouched (so the next pass
# retries) on abort.
class ApplySyncFilingOutcome
  class << self
    def call(operation)
      Runtime::Assert.invariant!(operation.kind == "sync_filing",
        "ApplySyncFilingOutcome: wrong kind #{operation.kind.inspect}")
      Runtime::Assert.invariant!(operation.terminal?,
        "ApplySyncFilingOutcome: operation not terminal (status=#{operation.status})")

      return unless operation.status == "succeeded"

      filing = Filing.find_by(id: operation.input["filing_id"])
      return if filing.nil?

      filing.update_columns(synced_at: Time.current)
    end
  end
end
