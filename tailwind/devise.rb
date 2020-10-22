# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
    gem 'devise'
    gem 'autoprefixer-rails'
    gem 'font-awesome-sass'
    gem 'amazing_print'
  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'dotenv-rails'
  RUBY
end

gsub_file('Gemfile', /# gem 'redis'/, "gem 'redis'")

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
########################################
if Rails.version < "6"
  scripts = <<~HTML
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
        <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  HTML
  gsub_file('app/views/layouts/application.html.erb', "<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>", scripts)
end
gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")
style = <<~HTML
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
      <%= stylesheet_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
HTML
gsub_file('app/views/layouts/application.html.erb', "<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>", style)


inject_into_file 'app/views/layouts/application.html.erb', after: '<body>' do
  <<-HTML
    <%= render 'shared/navbar' %>
    <%= render 'shared/flashes' %>
  HTML
end

# README
########################################
markdown_file_content = <<-MARKDOWN
File generated with mael-ha's template customization of LeWagon's template.
https://github.com/mael-ha/rails-templates
https://github.com/lewagon/rails-templates
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

environment generators

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  # generate('simple_form:install')
  generate(:controller, 'pages', 'home landmark', '--skip-routes', '--no-test-framework')

  # Routes
  ########################################
  route "root to: 'pages#home'"
  route "get 'landmark', to: 'pages#landing', as: :landing"
  # Git ignore
  ########################################
  append_file '.gitignore', <<~TXT
    # Ignore .env file containing credentials.
    .env*
    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<~RUBY
    class ApplicationController < ActionController::Base
    #{  "protect_from_forgery with: :exception\n" if Rails.version < "5.2"}  before_action :authenticate_user!
    end
  RUBY

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  generate('devise:views')

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<~RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :home, :landmark ]
      def home
      end
    end
  RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  ########################################
  run "yarn add tailwindcss"
  append_file 'app/javascript/packs/application.js', <<~JS
    // ----------------------------------------------------
    // Note(lewagon): ABOVE IS RAILS DEFAULT CONFIGURATION
    // WRITE YOUR OWN JS STARTING FROM HERE 👇
    // ----------------------------------------------------
    // External imports
    import "stylesheets/application";
    // Internal imports, e.g:
    // import { initSelect2 } from '../components/init_select2';
    document.addEventListener('turbolinks:load', () => {
      // Call your functions here, e.g:
      // initSelect2();
    });
  JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
    <<~JS
      const webpack = require('webpack');
      // Preventing Babel from transpiling NodeModules packages
      environment.loaders.delete('nodeModules');
    JS
  end

  # Dotenv
  ########################################
  run 'touch .env'

  # Rubocop
  ########################################
  run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # # configure application.js

  # configure postcss
  inject_into_file "postcss.config.js", "    require('tailwindcss')('.app/javascript/stylesheets/tailwind.config.js'),\n", after: "require('postcss-import'),\n"
  inject_into_file "postcss.config.js", "    require('autoprefixer'),\n", after: "plugins: [\n"

  # Assets - Setup Tailwind
  ########################################
  run 'rm -rf app/assets/stylesheets'
  run 'rm -rf vendor'
  run 'curl https://github.com/mael-ha/rails-templates/raw/master/tailwind/assets-stylesheets.zip > assets-stylesheets.zip'
  run 'unzip assets-stylesheets.zip -d app/assets && rm assets-stylesheets.zip && mv app/assets/assets-stylesheets app/assets/stylesheets'

  # generate stylesheets in app/javascript
  run 'curl -L https://github.com/mael-ha/rails-templates/raw/master/tailwind/js-stylesheets.zip > js-stylesheets.zip'
  run 'unzip js-stylesheets.zip -d app/javascript && rm js-stylesheets.zip'

  # # generate shared views in app/views includ. Tailwind components
  run 'curl -L https://github.com/mael-ha/rails-templates/raw/master/tailwind/shared.zip > shared.zip'
  run 'unzip shared.zip -d app/views && rm shared.zip'

  # Prepare Home and Landmark
  inject_into_file 'app/views/pages/home.html.erb', before: '<h1>' do
  <<-HTML
    <%= render 'shared/navbar' %>
  HTML
  end

  run "rm 'app/views/pages/landmark.html.erb'"
  file 'app/views/pages/landmark.html.erb', <<~HTML
    <%= render 'shared/tw_landing_page/landmark' %>
  HTML

  # Git
  ########################################
  # git add: '.'
  # git commit: "-m 'Initial commit with devise template from https://github.com/lewagon/rails-templates'"

  # Fix puma config
  gsub_file('config/puma.rb', 'pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }', '# pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }')
end
