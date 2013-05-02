require 'typhoeus/adapters/faraday'

# Public: Helper class for making requests to Instagram, because the Instagram
# gem largely sucks.
#
# Don't use a starting slash on the request URL.
#
# If there is an error, you will get either:
#
# Faraday::Error::ResourceNotFound or Faraday::Error::ClientError raised.
# 
#
# Usage - 
#
#   response = Star::Requester.get "media/popular"
#   # => Faraday::Response
#   response.body
#   # => Hashie::Mash
require Rails.root.join('lib', 'faraday_middleware', 'monitor_api_usage')
class Star::Requester

  # No need to use this, just rely on method_missing and treat it like
  # a Faraday connection object.
  def self.request
    @conn ||= Faraday.new(url: "https://api.instagram.com/v1/") do |faraday|

      faraday.response :mashify
      faraday.response :json

      faraday.response :monitor_api_usage,
        rate_limit_threshold: AppConfig.instagram.rate_limit_warning_threshold,
        action: ->(rate_limit_remaining, env) {
          mail = AdminMailer.instagram_rate_limit_warning(rate_limit_remaining, env[:url])
          mail.deliver if mail
        }

      faraday.response :follow_redirects
      faraday.response :raise_error

      faraday.adapter :typhoeus

    end
  end

  # Make this class a wrapper around a Faraday connection.
  def self.method_missing(method, *args, &block)
    self.request.send(method, *args, &block)
  end

end
