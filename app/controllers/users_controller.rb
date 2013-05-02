class UsersController < ApplicationController
  before_filter :authorized!, except: [:leaderboard, :verify]

  def verify
    if current_user and current_user.verified
      render json: current_user
    else
      render status: 401, json: {error: "not logged in"}
    end
  end

  # I'm deciding that Faraday sucks a little.
  # Also #like and #comment semantically should be in photos_controller, not
  # users_controller.
  def like
    method = request.method.downcase.to_sym
    url = "media/#{params[:uid]}/likes"
    query = "access_token=#{current_user.access_token}"
    if method == :delete
      response = Star::Requester.delete("#{url}?#{query}")
    elsif method == :post
      response = Star::Requester.post(url, query)
    end
    if photo = Photo.find_by_uid(params[:uid])
      photo.queue_for_updates(true)
    end
    render text: response.body.to_json, content_type: response.headers["Content-Type"]
  end

  def comment
    if !(Rails.env =~ /development/i)
      begin
        response = Star::Requester.post(
          "media/#{params[:uid]}/comments",
          {
            access_token: current_user.access_token,
            text: params[:text]
          }.to_param
        )
      rescue Faraday::Error::ClientError => e
        if e.message =~ /400/
          render status: 400, text: "Unauthorized"
        end
      else
        render text: response.body.to_json, content_type: response.headers["Content-Type"]
      end
    else
      render nothing: true
    end
  end

  def follow
    response = Star::Requester.post("users/#{params[:uid]}/relationship", {action: params[:relationship_action], access_token: current_user.access_token}.to_param)
    render text: response.body.to_json, content_type: response.headers["Content-Type"]
  end

  # Public: Show a leaderboard of all users and how many competitions they have
  # won.
  def leaderboard
    @leaderboard = User.star_score_leaderboard
    @top_10 = @leaderboard[0,10]
    @users_position = @leaderboard.index{|u| u == current_user} if current_user
  end

  def profile
    @photos_submitted = current_user.photos.to_a.count{|p| !p.campaigns.empty?}
    @won = current_user.winning_photos.count
  end
  
  def update_profile
    # safety first! this check can probably come out.
    a = params[:user].select{|k,v| k.to_s == "can_receive_mail"}
    current_user.update_attributes! a
    redirect_to profile_user_path, :notice => "Updated your preferences"
  end
  

end
