Rails.application.config.middleware.use OmniAuth::Builder do
  provider :instagram,
    AppConfig.instagram.client_id,
    AppConfig.instagram.client_secret,
    scope: "comments relationships likes"
end
