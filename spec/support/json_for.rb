# Copy pasta from application_controller
def default_serializer_options
  {root: false}
end

def json_for(target, options = {})
  options = default_serializer_options.merge(options)
  options[:scope] ||= self
  target.active_model_serializer.new(target, options).to_json
end
