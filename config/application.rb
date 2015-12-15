# coding: utf-8
require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'amazon/ecs'
require 'csv'
require 'nkf'
require 'zipruby'
require 'open-uri'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AmazonProductSearch
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    Amazon::Ecs.options = {
      :AWS_access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :AWS_secret_key    => ENV["AWS_SECRET_KEY"],
      :associate_tag     => ENV["ASSOCIATE_TAG"]
    }
    # for debug
    # Amazon::Ecs.debug = true

    # deviseの言語設定
    config.i18n.default_locale = :ja
    # DBはUTCのまま、表示のみをJSTにする
    config.time_zone = 'Tokyo'
  end
end
