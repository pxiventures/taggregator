class UserSerializer < ActiveModel::Serializer
  attributes :full_name, :profile_picture, :username, :follows, :followed_by, :media, :id, :uid
end
