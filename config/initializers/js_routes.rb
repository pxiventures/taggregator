JsRoutes.setup do |config|
  config.exclude = [/_?admin_?/, /_?auth_?/, /sidekiq/, /verify/, /rails_info/]
end
