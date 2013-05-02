class Star
end

Dir[File.dirname(__FILE__) + "/star/*.rb"].each{|f| require f}
