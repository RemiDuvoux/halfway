class Airport < ApplicationRecord
  belongs_to :city
  has_many :flights

  validates :iata_code, presence: true

  def name
    self.city.name
  end

end
