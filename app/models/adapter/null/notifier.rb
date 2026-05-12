# Null implementation of Port::Notifier — logs the would-be email and
# returns a synthetic delivery confirmation. Default binding until a
# real SMTP / transactional-email adapter ships.
module Adapter
  module Null
    class Notifier < Adapter::Base
      class << self
        def port_module
          Port::Notifier
        end

        def _perform(input)
          Rails.logger.info(
            "[Null::Notifier] would deliver to=#{input['recipient']} subject=#{input['subject'].inspect}"
          )
          {
            "delivered_at"        => Time.current.iso8601,
            "provider_message_id" => "null-msg-#{SecureRandom.hex(8)}"
          }
        end
      end
    end
  end
end
