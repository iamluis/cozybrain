namespace :demo do
  desc "Seed (or refresh) a realistic multi-year demo user. " \
       "Vars: USER_EMAIL (default demo@cozyedge.tech), USER_PASSWORD " \
       "(default demodemo123), YEARS (default 3 — covers years-back+current)."
  task seed: :environment do
    email    = ENV.fetch("USER_EMAIL",    "demo@cozyedge.tech")
    password = ENV.fetch("USER_PASSWORD", "demodemo123")
    years    = ENV.fetch("YEARS",         "3").to_i

    DemoSeeder.new(email: email, password: password, years_back: years).run!
  end
end
