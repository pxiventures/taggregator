# Internal: Controller for managing campaigns. Lets you view, edit and
# create campaigns and send out emails.
class Admin::CampaignsController < AdminController
  load_and_authorize_resource

  def index
    redirect_to admin_root_path
  end

  def show
  end

  def new
  end

  def create
    if @campaign.save
      redirect_to [:admin, @campaign], :notice => "Successfully created campaign."
    else
      render :action => 'new'
    end
  end

  def quick_add
    tag_name = params[:tag]
    tag_name.slice!(0) if tag_name.starts_with? "#"
    campaign = Campaign.quick_add params[:name], tag_name
    if campaign.valid? and campaign.persisted?
      redirect_to admin_root_path, notice: "Successfully quick-added campaign."
    else
      redirect_to admin_root_path, alert: campaign.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @campaign.update_attributes(params[:campaign])
      redirect_to [:admin, @campaign], :notice  => "Successfully updated campaign."
    else
      render :action => 'edit'
    end
  end

  def set_winning_photo
    redirect_to [:admin, @campaign], alert: "That campaign had no photos!" and return if @campaign.approved_photos.count == 0
    winning_photo = @campaign.ranked_photos.first
    @campaign.winning_photo = winning_photo
    @campaign.save

    redirect_to [:admin, @campaign], notice: "OK, set winning photo"
  end

  def destroy
    @campaign = Campaign.find(params[:id])
    @campaign.destroy
    redirect_to admin_root_path, :notice => "Successfully destroyed campaign."
  end
end
