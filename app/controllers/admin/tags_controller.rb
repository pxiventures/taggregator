# Internal: CRUD for making tags.
class Admin::TagsController < AdminController

  # Autocomplete endpoint.
  def index
    respond_to do |format|
      format.json {
        tags = Tag.where('name LIKE ?', "%#{params[:q]}%").limit(20).order('name')
        render :json => tags.map(&:attributes)
      }
    end
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = Tag.new params[:tag]
    if @tag.save
      # Disabled for now
      # @tag.get_recent_media
      redirect_to admin_root_path, notice: "Successfully created tag."
    else
      render action: "new"
    end
  end

end
