class AddIndexesForTripsAndRequestReports < ActiveRecord::Migration[5.0]
  def change
    add_index :trips, :trip_time
    add_index :trips, :arrive_by
    add_index :trips, :external_purpose
    add_index :trips, :details
    add_index :trips, :disposition_status

    add_index :waypoints, :street_number
    add_index :waypoints, :route
    add_index :waypoints, :city
    add_index :waypoints, :state
    add_index :waypoints, :zip
    add_index :waypoints, :lat
    add_index :waypoints, :lng

    add_index :purposes, :code

    add_index :request_logs, :status_code
    # add_index :request_logs, :params, using: :gist
    add_index :request_logs, :auth_email
    add_index :request_logs, :duration
  end
end
