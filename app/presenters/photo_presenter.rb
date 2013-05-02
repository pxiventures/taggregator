# Use the Photo Presenter to 'present' photo content, for example the
# thumbnail, links to social networks. That kind of thing.
#
# In a view:
#
# - present @photo do |photo_presenter|
#   %strong 
#     = photo_presenter.position_in_campaigns
#
# # => <strong>3rd in 'Something sweet'</strong>
#   
class PhotoPresenter < BasePresenter
  presents :photo

  # Construct a sentence of position & campaign pairs. Optionally provide a
  # subset of campaigns to restrict the sentence to.
  #
  # photo.position_in_campaigns
  # # => "4th in Something Sweet and 2nd in Simply Red"
  def position_in_campaigns(campaigns=photo.campaigns, campaign_links=true)
    campaigns = campaigns.to_a unless campaigns.is_a? Array
    campaigns_in_sentence = photo.campaigns.select{|c| campaigns.include? c}
    phrases = campaigns_in_sentence.map{|c|
      [
        photo.position_in(c).ordinalize,
        "in",
        (campaign_links ? h.link_to(c.name, campaign_path(c, only_path: false)) : c.name)
      ].join(" ")
    }
    phrases.to_sentence.html_safe
  end

  def caption
    photo.caption.blank? ? "uncaptioned photo" : photo.caption
  end

  # Thumbnail that links to Instagram
  #
  # image_options - options to pass to the image tag.
  def instagram_thumbnail(image_options={})
    h.link_to photo.url, target: "_blank" do
      h.image_tag photo.thumbnail_url, image_options
    end
  end

  # Tweet link
  def tweet(campaigns=photo.campaigns)
    campaigns = campaigns.to_a unless campaigns.is_a? Array
    campaign_to_tweet_about = photo.campaigns.select{|c| campaigns.include? c}.first
    if campaign_to_tweet_about
      tweet_text = "My Instagram photo came #{photo.position_in(campaign_to_tweet_about).ordinalize} in a recent competition on #{AppConfig.app_name}"
    else
      tweet_text = "My Instagram photo was in a recent competition on #{AppConfig.app_name}" 
    end
    h.link_to "Twitter", twitter_intent_url("tweet", url: h.root_url(only_path: false), text: tweet_text)
  end

  def facebook(campaigns=photo.campaigns)
    campaigns = campaigns.to_a unless campaigns.is_a? Array
    campaign_to_post_about = photo.campaigns.select{|c| campaigns.include? c}.first
    text = "I came #{photo.position_in(campaign_to_post_about).ordinalize} in '#{campaign_to_post_about.name}' on #{AppConfig.app_name}"
    h.link_to "Facebook", fb_feed_post_url(photo, campaign_to_post_about, text)
  end
  
end
