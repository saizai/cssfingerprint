# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :domain => ".cssfingerprint.com", # enables sharing w/ wildcard subdomains
  :key    => '_historyprint_session_2',
  :secret => '3e115e5a12b9d959b9cd75b0be1d52880f9d784c50b7b10b120487fba819cba7e43c86b737b0f6716b6de8d8f9707cfc5e5bd225e88105e037a2b0efc00d6395'
#  :secret => 'c247137bd2530a0c137b08f8698137182a2a9af4ad3573b19a3922d89dc9464a396a1515f8d51fe3fc8c7e911056d685f3777295045f381e72f27be65991eb97'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
