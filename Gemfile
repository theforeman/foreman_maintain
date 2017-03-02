source 'https://rubygems.org'

gemspec

gem 'pry'

if RUBY_VERSION <= '1.8.7'
  gem 'json'
end

if RUBY_VERSION >= '2.0'
  gem 'rubocop'
else
  gem 'clamp', '~> 0.6.2'
  gem 'highline', '~> 1.6.21'
end
