require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'
 
module RailsAdminUpdateMetrics
end
 
module RailsAdmin
  module Config
    module Actions
      class UpdateMetrics < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :visible? do
          authorized? && bindings[:object].respond_to?(:update_metrics)
        end

        register_instance_option :member? do
          true
        end

        register_instance_option :link_icon do
          'icon-refresh'
        end

        register_instance_option :controller do
          Proc.new do
            @object.update_metrics
            flash[:notice] = "Metrics for #{@object} have been updated"
         
            redirect_to back_or_index
          end
        end
      end
    end
  end
end
