namespace :users do
  desc "Create or update a user. Reads USER_EMAIL + USER_PASSWORD env vars."
  task create: :environment do
    email    = ENV.fetch("USER_EMAIL")    { abort "USER_EMAIL not set" }
    password = ENV.fetch("USER_PASSWORD") { abort "USER_PASSWORD not set" }

    user = User.find_or_initialize_by(email_address: email)
    user.password = password
    user.save!

    puts "#{user.persisted? ? '✓' : '⚠'}  user #{user.email_address} (id #{user.id})"
  end
end
