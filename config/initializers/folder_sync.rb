Rails.application.config.x.folder_sync_root =
  ENV.fetch("FOLDER_SYNC_ROOT") { Rails.root.join("tmp/folder_sync").to_s }
