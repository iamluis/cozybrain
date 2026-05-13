# Port for syncing one Filing's blob(s) into the gestoría folder tree.
# Adapters write to a target (local disk + cloud-synced root, S3, etc.)
# and return the path/timestamp.
module Port
  module FolderSync
    INPUT_SHAPE = {
      "filing_id"   => Integer,
      "target_path" => String,
      "blob_key"    => String
    }.freeze

    OUTPUT_SHAPE = {
      "synced_at"   => String,
      "remote_path" => String
    }.freeze

    module_function

    def assert_input!(input)
      Runtime::Assert.shape!(input, INPUT_SHAPE, where: "Port::FolderSync input")
    end

    def assert_output!(output)
      Runtime::Assert.shape!(output, OUTPUT_SHAPE, where: "Port::FolderSync output")
    end
  end
end
