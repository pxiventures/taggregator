# RailsAdmin config file. Generated on January 08, 2013 14:38
# See github.com/sferik/rails_admin for more informations

require './lib/rails_admin_update_metrics'

RailsAdmin.config do |config|

  ################  Global configuration  ################

  # Set the admin name here (optional second array element will appear in red). For example:
  config.main_app_name = [AppConfig.app_name, 'Admin']

  config.authenticate_with{}
  config.current_user_method { current_user } # auto-generated
  config.authorize_with do
    is_admin? || access_denied
  end

  config.actions do
    dashboard
    index
    new
 
    update_metrics
 
    show
    edit
    export
    delete
  end
  
  config.attr_accessible_role { :admin }

  # If you want to track changes on your models:
  # config.audit_with :history, 'Admin'

  # Or with a PaperTrail: (you need to install it first)
  # config.audit_with :paper_trail, 'Admin'

  # Display empty fields in show views:
  # config.compact_show_view = false

  # Number of default rows per-page:
  # config.default_items_per_page = 20

  # Exclude specific models (keep the others):
  # config.excluded_models = ['Campaign', 'CampaignTag', 'Photo', 'PhotoTag', 'Tag', 'User']

  # Include specific models (exclude the others):
  # config.included_models = ['Campaign', 'CampaignTag', 'Photo', 'PhotoTag', 'Tag', 'User']

  # Label methods for model instances:
  # config.label_methods << :description # Default is [:name, :title]


  ################  Model configuration  ################

  # Each model configuration can alternatively:
  #   - stay here in a `config.model 'ModelName' do ... end` block
  #   - go in the model definition file in a `rails_admin do ... end` block

  # This is your choice to make:
  #   - This initializer is loaded once at startup (modifications will show up when restarting the application) but all RailsAdmin configuration would stay in one place.
  #   - Models are reloaded at each request in development mode (when modified), which may smooth your RailsAdmin development workflow.

end

