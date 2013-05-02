class CampaignPresenter < BasePresenter
  presents :campaign
  
  delegate :name, to: :campaign

  def tags
    campaign.tags.map{|t| "##{t.name}"}.to_sentence
  end

  def number_of_users
    [
      h.pluralize(campaign.participating_users.count, "user"),
      (campaign.ended? ? "participated" : "is".pluralize(campaign.participating_users.count)),
      "in this competition"
    ].join(" ")
  end

end
