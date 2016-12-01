class TripsController < ApplicationController
  skip_before_action :authenticate_user!
  def create
    city = City.find(params[:city_id])
    trip_1 = Trip.new
    trip_1.city = city
    trip_1.save
    trip_2 = Trip.new
    trip_2.city = city
    trip_2.trip = trip_1
    trip_2.save
    trip_1.trip = trip_2
    trip_1.save
    flight_1 = Flight.create(departure_time: params[:flight_1_departure_time], arrival_time: params[:flight_1_arrival_time], departure_airport_iata_code: params[:flight_1_departure_airport], arrival_airport_iata_code: params[:flight_1_arrival_airport])
    flight_1.trip = trip_1
    flight_1.save
    flight_2 = Flight.create(departure_time: params[:flight_2_departure_time], arrival_time: params[:flight_2_arrival_time], departure_airport_iata_code: params[:flight_2_departure_airport], arrival_airport_iata_code: params[:flight_2_arrival_airport])
    flight_2.trip = trip_1
    flight_2.save
    flight_3 = Flight.create(departure_time: params[:flight_3_departure_time], arrival_time: params[:flight_3_arrival_time], departure_airport_iata_code: params[:flight_3_departure_airport], arrival_airport_iata_code: params[:flight_3_arrival_airport])
    flight_3.trip = trip_2
    flight_3.save
    flight_4 = Flight.create(departure_time: params[:flight_4_departure_time], arrival_time: params[:flight_4_arrival_time], departure_airport_iata_code: params[:flight_4_departure_airport], arrival_airport_iata_code: params[:flight_4_arrival_airport])
    flight_4.trip = trip_2
    flight_4.save
    redirect_to city_trip_path(city, trip_1)
  end

  def show
    @city = City.find(params[:city_id])
    @trip_1 = Trip.find(params[:id])
    @trip_2 = @trip_1.trip
  end
end
