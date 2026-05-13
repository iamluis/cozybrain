# Writes a blob to a directory tree on disk under
# `Rails.configuration.x.folder_sync_root`. v1: cheap and reliable — the
# user keeps that root inside Dropbox/iCloud/Drive and the cloud tool
# handles the actual gestoría-facing sync.
#
# Idempotent: re-running with the same blob + target_path overwrites the
# file (the source of truth is the DB row; the disk is a projection).
module Adapter
  module Local
    class FolderSync < Adapter::Base
      class << self
        def port_module
          Port::FolderSync
        end

        def _perform(input)
          root = Rails.configuration.x.folder_sync_root
          raise "folder_sync_root not configured" if root.blank?

          target = File.join(root, input["target_path"])
          FileUtils.mkdir_p(File.dirname(target))

          blob = ActiveStorage::Blob.find_by(key: input["blob_key"])
          raise "blob not found: #{input['blob_key']}" if blob.nil?

          blob.open do |source|
            File.binwrite(target, source.read)
          end

          {
            "synced_at"   => Time.current.iso8601,
            "remote_path" => target
          }
        end
      end
    end
  end
end
