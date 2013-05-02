class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, :to => :crud

    if user
      if user.admin?
        can :manage, :all
      elsif user.sponsor
        can :crud, Campaign, sponsor_id: user.sponsor.id
        can :set_winning_photo, Campaign, sponsor_id: user.sponsor.id
        can :update, CampaignPhoto, campaign: {id: user.sponsor.campaign_ids}
      end
    end
  end
end
