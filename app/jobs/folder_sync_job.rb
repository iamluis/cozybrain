# Scans untrashed Filings for ones whose blob needs (re)syncing — never
# synced, OR updated since the last sync. Enqueues one Operation per
# filing; Dispatcher routes to Adapter::Local::FolderSync (default).
#
# Idempotent: re-running picks up only filings still due. The Operation
# carries the filing's blob key + target_path; the adapter overwrites
# the file on disk.
class FolderSyncJob < ApplicationJob
  queue_as :default

  def perform(filing_id: nil)
    if filing_id
      enqueue_for(Filing.find(filing_id))
    else
      filings_needing_sync.find_each(&method(:enqueue_for))
    end
  end

  private

  def filings_needing_sync
    Filing.untrashed.where("synced_at IS NULL OR synced_at < updated_at")
  end

  def enqueue_for(filing)
    blob = filing.primary_blob
    return if blob.nil?  # nothing to sync yet (e.g. an invoice without a PDF)

    correlation_id = "sync_filing:#{filing.id}:#{filing.updated_at.to_i}"
    return if Operation.exists?(correlation_id: correlation_id)

    operation = Operation.create!(
      kind:           "sync_filing",
      adapter_name:   Runtime::Dispatcher.adapter_for(Port::FolderSync).name,
      correlation_id: correlation_id,
      max_attempts:   5,
      input: {
        "filing_id"   => filing.id,
        "target_path" => filing.target_path,
        "blob_key"    => blob.key
      }
    )
    OperationJob.perform_later(operation.id)
  end
end
