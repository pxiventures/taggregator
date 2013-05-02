module ApplicationHelper

  # Present an object.
  def present(object, klass = nil)
    klass ||= "#{object.class}Presenter".constantize
    presenter = klass.new(object, self)
    yield presenter if block_given?
    presenter
  end

  # Public: Returns an <li> that has a class of 'active' if the route you
  # supplied is the page the user is currently on.
  #
  # Example:
  #
  #   nav_link("Home", root_path)
  #   # => '<li class="active"><a href="/">Home</a></li>'
  #   # (If the helper is called on the home page)
  def nav_link(text, route)
    content_tag(:li, class: current_page?(route) ? "active" : "") do
      link_to text, route
    end
  end

  # Public: Returns the hash of the current deployed revision.
  # If you're not in production this just returns 'Undeployed'
  def application_revision
    return @revision if @revision
    if !(Rails.env =~ /production/i)
      @revision = 'Undeployed'
    else
      @revision = File.read(File.join(Rails.root, "REVISION"))
    end
  end

  def twitter_intent_url(intent, options)
    "https://twitter.com/intent/#{intent}?#{options.to_param}"
  end
  
  def fb_feed_post_url(photo, campaign, text=nil)
    text = "I'm coming #{photo.position_in(campaign).ordinalize} in '#{campaign.name}' on #{AppConfig.app_name}" unless text
    qs = {
      app_id: AppConfig.facebook.app_id,
      redirect_uri: facebook_callback_url(only_path: false),
      link: root_url(only_path: false),
      picture: photo.image_url,
      name: text,
      caption: photo.caption,
      description: text,
      display: "popup"
    }.to_param
    
    "https://www.facebook.com/dialog/feed?#{qs}"
  end

  def fb_feed_post_win(user, rank)
    qs = {
      app_id: AppConfig.facebook.app_id,
      redirect_uri: facebook_callback_url(only_path: false),
      link: leaderboard_user_url(only_path: false),
      picture: user.profile_picture,
      name: "#{AppConfig.app_name} superstart",
      caption: "The face of a winner!",
      description: "#{user.full_name} is #{rank.ordinalize} in the world on #{AppConfig.app_name}! Check their win!",
      display: "popup"
    }.to_param
    
    "https://www.facebook.com/dialog/feed?#{qs}"
  end

end
