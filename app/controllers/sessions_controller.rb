class SessionsController < ApplicationController

  # Public: Callback from Instagram.
  def create
    auth = request.env["omniauth.auth"]

    # Don't allow private users to play :(
    if AppConfig.only_public_users
      begin
        response = Star::Requester.get "users/#{auth.uid}", {client_id: AppConfig.instagram.client_id}
      rescue Faraday::Error::ClientError => e
        if e.message =~ /400/
          redirect_to root_path(:private => true) and return
        end
      end
    end

    user = User.find_by_uid(auth.uid) || User.create_with_omniauth(auth)

    if User.count == 1
      user.admin = true
      user.save!
    end

    if user.last_signed_in_at.nil?
      session[:first_sign_in] = true
    end

    user.update_attributes({
      access_token: auth.credentials.token,
      profile_picture: auth.info.image,
      full_name: auth.info.name,
      last_signed_in_at: Time.now
    })
    session[:user_id] = user.id
    redirect_to photos_path, notice: "Signed in!"
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "You are now logged out"
  end

  # Public: Capture a user's email address
  def email
    redirect_to root_path, alert: "You must be logged in" and return unless current_user
  end

  def update_email
    redirect_to root_path, alert: "You must be logged in" and return unless current_user
    current_user.email = params[:email]
    # TODO: Should we reset the verification token here?
    current_user.verified = false
    if current_user.save and UserMailer.verify_email(current_user).deliver
      redirect_to photos_path, notice: "All done!"
    else
      redirect_to email_path, alert: "There was an error: #{current_user.errors.full_messages.to_sentence}"
    end
  end

  # Public: Verify a user's email address (they come here from the email we
  # send). We're being nice and not needing them to be logged in still (a la
  # hip sites).
  def verify
    user = User.find_by_verification_token(params[:t])
    if user and !user.verified
      user.verified = true
      user.save
      session[:user_id] = user.id
      # Assume people are probably new. Not always the case; they may have
      # changed their email address. But that functionality isn't even exposed
      # yet.
      session[:first_sign_in] = true
      redirect_to photos_path
    else
      redirect_to root_path, alert: "You don't need to be there."
    end
  end

end
