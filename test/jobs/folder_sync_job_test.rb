require "test_helper"

class FolderSyncJobTest < ActiveJob::TestCase
  setup do
    @receipt = receipts(:lab900_dinner)
    @receipt.original_photo.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample_receipt.png")),
      filename:     "receipt.png",
      content_type: "image/png"
    )
    Filing.update_all(synced_at: nil)
  end

  test "enqueues sync_filing Operations only for filings needing sync" do
    # Only the dinner receipt has a blob; others don't have attachments
    # in the fixture environment, so they won't get enqueued.
    assert_difference -> { Operation.where(kind: "sync_filing").count } => 1 do
      FolderSyncJob.perform_now
    end
  end

  test "is idempotent: a second run with no Filing changes enqueues nothing new" do
    FolderSyncJob.perform_now
    assert_no_difference -> { Operation.where(kind: "sync_filing").count } do
      FolderSyncJob.perform_now
    end
  end

  test "filing_id form syncs just one filing" do
    f = filings(:lab900_dinner_filing)
    assert_difference -> { Operation.where(kind: "sync_filing").count } => 1 do
      FolderSyncJob.perform_now(filing_id: f.id)
    end
  end
end
