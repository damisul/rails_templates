def commit_changes(message)
  git add: '.'
  git commit: "-m '#{message}'"
end

git :init
commit_changes 'Initial commit'

def install_dotenv
  gem_group :test, :development do
    gem 'dotenv-rails'
  end

  insert_into_file '.gitignore', <<~CODE
    # Ignore IDE settings
    .idea
  
    # Ignore machine-specific settings for dotenv-rails gem
    .env.*.local
  CODE

  db_user = ask "Local DB user name (leave empty for default 'postgres' value):"
  if db_user.blank?
    db_user = 'postgres'
  end

  db_password = ask "Local DB password (leave empty for default 'postgres' value):"
  if db_password.blank?
    db_password = 'postgres'
  end

  file '.env.test', <<~CODE
    DATABASE_URL=postgres://#{db_user}:#{db_password}@localhost:5432/#{app_name}_test
  CODE

  file '.env.development', <<~CODE
    DATABASE_URL=postgres://#{db_user}:#{db_password}@localhost:5432/#{app_name}_development
  CODE

  remove_file 'config/database.yml'
  file 'config/database.yml', <<~CODE
    default: &default
      adapter: postgresql
      encoding: unicode
      pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
      url: <%= ENV['DATABASE_URL'] %>
  
    development:
      <<: *default
  
    test:
      <<: *default
  
    production:
      <<: *default
  CODE
  run 'bundle install'
  rails_command 'db:create', env: 'test'
  rails_command 'db:create', env: 'development'

  commit_changes 'Added dotenv-rails gem and used it for database configuration'
end

def install_rspec
  gem_group :test do
    gem 'faker'
  end

  gem_group :test, :development do
    gem 'byebug'
    gem 'factory_bot_rails'
    gem 'rspec'
  end
end

def install_active_storage
  gem_group :development, :production do
    gem 'aws-sdk-s3'
  end
  run 'bundle install'
  insert_into_file '.env.development', <<~CODE
    S3_ACCESS_KEY_ID=<SET VALUE>
    S3_SECRET_ACCESS_KEY=<SET VALUE>
    S3_STORAGE_BUCKET=<SET VALUE>
  CODE

  remove_file 'config/storage.yml'
  file 'config/storage.yml', <<~CODE
    test:
      service: Disk
      root: <%= Rails.root.join("tmp/storage") %>
    
    amazon:
      service: S3
      access_key_id: <%= ENV['S3_ACCESS_KEY_ID'] %>
      secret_access_key: <%= ENV['S3_SECRET_ACCESS_KEY'] %>
      region: eu-central-1
      bucket: <%= ENV['S3_STORAGE_BUCKET'] %>
  CODE

  gsub_file 'config/environments/development.rb',
    /config.active_storage.service = :local/,
    'config.active_storage.service = :amazon'

  gsub_file 'config/environments/production.rb',
    /config.active_storage.service = :local/,
    'config.active_storage.service = :amazon'

  rails_command 'active_storage:install'
  rails_command 'db:migrate', env: :development

  run 'bundle install'
  commit_changes 'Settings for ActiveStorage'
end

install_dotenv

gem_group :development do
  gem 'rubocop'
end

install_rspec

if yes?('Add Active Storage?')
  install_active_storage
end
