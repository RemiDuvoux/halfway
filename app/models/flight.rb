class Flight < ApplicationRecord
  belongs_to :trip
  belongs_to :airport_departure, foreign_key: :airport_departure_id, class_name: 'Airport'
  belongs_to :airport_arrival, foreign_key: :airport_arrival_id, class_name: 'Airport'

  validates :departure_time, presence: :true
  validates :arrival_time, presence: :true
end
