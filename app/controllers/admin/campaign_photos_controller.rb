# Internal: Administrative panel for moderating photos.
class Admin::CampaignPhotosController < AdminController
  def index
    @campaign = Campaign.find params[:campaign_id]
    @campaign_photos = @campaign.campaign_photos
      .includes(:photo)
      .where(moderated: false)
      .order("created_at ASC")
      .page(params[:page])
  end

  def update
    @campaign = Campaign.find params[:campaign_id]
    @campaign_photo = @campaign.campaign_photos.find params[:id]
    if @campaign_photo.update_attributes(params[:campaign_photo])
      redirect_to admin_campaign_photos_path(@campaign), notice: "Moderated"
    else
      redirect_to admin_campaign_photos_path(@campaign), alert: "Error: #{@campaign_photo.errors.full_messages.to_sentence}"
    end
  end

end
