def stub_requester
  Star::Requester.stub(:get) do |path|
    body = if path =~ /users/
      InstagramResponses.user
    elsif path =~ /tags/
      Hashie::Mash.new(data: [])
    elsif path =~ /media\/.+?\/comments/
      Hashie::Mash.new(data: [{from: {id: "nocollision"}}])
    elsif path =~ /media\/.+?\/likes/
      Hashie::Mash.new(data: [{id: "nocollision"}])
    elsif path =~ /media/
      InstagramResponses.photo
    end
    double("response", success?: true, body: body)
  end

  Star::Requester.stub(:post) do |path|
    double("response", success?: true, body: [], headers: {})
  end
end
