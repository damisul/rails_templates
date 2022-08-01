# Preface

This template sets default preferences I prefer to have in my Rails projects,
namely:
- Rubocop linter
- Rspec/FactoryBot/Faker for tests instead of standard minitest/fixtures
- devise for auth
- dotenv gem for storing app configuration

More details on writing Rails templates can be found here: 
https://guides.rubyonrails.org/rails_application_templates.html

# How to use

when creating new project simply run:
```
rails new <PROJECT_NAME> -m https://github.com/damisul/rails_templates/blob/master/app.rb
```