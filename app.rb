git :init
git add: '.'
git commit: "-m 'Initial commit'"

gem_group :test, :development do
  gem 'dotenv-rails'
end

run "echo '.idea' >> .gitignore"
run "echo '.env.*.local' >> .gitignore"

db_user = ask("Local DB user name (leave empty for default 'postgres' value):")
if db_user.blank?
  db_user = 'postgres'
end

db_password = ask("Local DB password (leave empty for default 'postgres' value):")
if db_password.blank?
  db_password = 'postgres'
end

file '.env.test', <<~CODE
  DATABASE_URL=postgres://#{db_user}:#{db_password}@localhost:5432/#{app_name}_test
CODE

env_dev = <<~CODE
  DATABASE_URL=postgres://#{db_user}:#{db_password}@localhost:5432/#{app_name}_development
CODE

if yes?('Add Active Storage?')
  gem_group :development, :production do
    gem 'aws-sdk-s3'
  end
  rails_command 'active_storage:install'
  env_dev << <<~CODE
    S3_ACCESS_KEY_ID=<SET VALUE>
    S3_SECRET_ACCESS_KEY=<SET VALUE>
    S3_STORAGE_BUCKET=<SET VALUE>
  CODE
end

file '.env.development', env_dev

run 'rm config/database.yml'
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
rails_command 'db:create', env: :test
rails_command 'db:create', env: :development
rails_command 'db:migrate', env: :development

git add: '.'
git commit: "-m 'Added dotenv-rails gem and used it for database configuration'"

rails_command 'webpacker:install'
rails_command 'webpacker:install:react'
rails_command 'webpacker:install:erb'

git add: '.'
git commit: "-m 'Installed webpacker with React'"
