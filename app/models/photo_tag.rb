class PhotoTag < ActiveRecord::Base
  attr_accessible :photo, :tag, :photo_id, :tag_id, :sticky

  validates :tag_id, uniqueness: {scope: :photo_id}

  belongs_to :photo, touch: true
  belongs_to :tag
end
