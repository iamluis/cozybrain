# Port for sending one notification (transactional email today; could be SMS
# or push in the future). Adapters deliver and return a confirmation handle.
module Port
  module Notifier
    INPUT_SHAPE = {
      "recipient" => String,
      "subject"   => String,
      "body_text" => String,
      "body_html" => String
    }.freeze

    OUTPUT_SHAPE = {
      "delivered_at"        => String,
      "provider_message_id" => String
    }.freeze

    module_function

    def assert_input!(input)
      Runtime::Assert.shape!(input, INPUT_SHAPE, where: "Port::Notifier input")
    end

    def assert_output!(output)
      Runtime::Assert.shape!(output, OUTPUT_SHAPE, where: "Port::Notifier output")
    end
  end
end
