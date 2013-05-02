require 'yaml'

module InstagramResponses

  @responses = {}

  class << self

    Dir.glob(File.join(File.dirname(__FILE__), "..", "fixtures", "instagram_responses", "*")).each do |f|
      define_method File.basename(f).chomp(File.extname(f)) do
        @responses[f] ||= Hashie::Mash.new YAML.load(File.read(f))
      end
    end

  end
  
end
