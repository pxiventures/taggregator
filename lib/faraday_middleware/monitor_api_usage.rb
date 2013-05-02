# Internal: Custom Faraday Middleware to inspect the Instagram rate limit
# header and perform some action if it is below a threshold.
#
# Example
#
#   use FaradayMiddleware::MonitorApiUsage,
#     rate_limit_threshold: 100,
#     action: ->(rate_limit_remaining, env) {
#       warn_admins_about_rate_limit(limit)
#     }
module FaradayMiddleware
  class MonitorApiUsage < Faraday::Response::Middleware

    # Public: Initialize the middleware. The middleware itself takes 2 options:
    #
    # rate_limit_threshold - threshold before warning about the rate limit.
    # action - lambda action to perform if below the threshold, takes 2
    #          arguments - the rate limit remaining and the env variable the
    #          middleware receives.
    # header - Header to look for, defaults to X-Ratelimit-Remaining.
    def initialize(app, options = {})
      super(app)
      @options = options
      @options[:rate_limit_threshold] ||= 1000
      @options[:action] ||= ->(rate_limit_remaining, env) {
        warn "API limit is getting low (#{rate_limit_remaining})"
      }
      @options[:header] ||= "X-Ratelimit-Remaining"
    end

    def call(env)
      @app.call(env).on_complete do |env|
        if env[:response_headers]
          remaining = env[:response_headers][@options[:header]]
          if remaining && remaining.to_i < @options[:rate_limit_threshold]
            @options[:action].call(remaining, env)
          end
        end
      end
    end
  end
end

Faraday.register_middleware :response,
  :monitor_api_usage => lambda { FaradayMiddleware::MonitorApiUsage }
