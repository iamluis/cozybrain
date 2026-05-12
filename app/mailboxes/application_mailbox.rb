class ApplicationMailbox < ActionMailbox::Base
  # Every authenticated forwarded email lands here; classification is
  # done downstream via the integration spine, not at routing time.
  routing all: :inbox
end
