source 'https://rubygems.org'
ruby '2.0.0'

gem 'rails', '~> 3.2.13'
gem 'pg'
gem 'haml-rails'
gem 'yappconfig'
gem 'unicorn'
gem 'active_model_serializers'

gem 'hiredis'
gem 'redis', require: ["redis", "redis/connection/hiredis"]
gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'clockwork'
gem 'slim'
gem 'sinatra', '>= 1.3.0', :require => nil

gem 'omniauth'
gem 'omniauth-instagram'
gem 'cancan'

gem 'typhoeus', '~> 0.6.0'
gem 'faraday'
gem 'faraday_middleware'

gem 'rails_admin'
gem 'simple_form'
gem 'kaminari'

gem 'js-routes'
gem 'gon'

gem 'instagram'

gem 'maruku'

group :production do
  gem 'dalli'
  gem 'memcachier'
end

group :development do
  gem 'mailcatcher', require: false
  gem 'nifty-generators'
  gem 'foreman'
end

group :assets do
  gem 'sass-rails'
  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails'
  gem 'bootstrap-sass', '~> 2.2.2.0'
  gem 'turbo-sprockets-rails3'
  gem 'font-awesome-rails'
end

gem 'jquery-rails'

gem 'rspec-rails', :group => [:test, :development]
group :test do
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'guard-rspec'
  gem 'launchy'
  gem 'spork-rails'
  gem 'guard-spork'
  gem 'rb-fsevent', :require => false
  gem 'ruby_gntp'
end
