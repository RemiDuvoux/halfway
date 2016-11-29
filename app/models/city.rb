class City < ApplicationRecord
  has_many :airports
  validates :name, presence: true

  has_attachment :background_photo
  has_attachment :card_photo
end
