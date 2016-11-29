class Trip < ApplicationRecord
  belongs_to :trip
  belongs_to :city
  has_many :flights
end
