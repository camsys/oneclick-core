class Landmark < Place

  ### Validations ####
  validates :name, uniqueness: true
  validates :name, presence: true
  validates :lat , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  #### Scopes ####
  scope :is_old, -> { where(:old => true) }
  scope :is_new, -> { where(:old => false) }

  #### METHODS ####
  # Load new landmarks from CSV
  # CSV must have the following columns: Name, Street Number, Route, Address, City, State, Zip, Lat, Lng, Types
  def self.update file
    #require 'open-uri'
    require 'csv'
    landmarks_file = open(file)

    # Iterate through CSV.
    failed = false
    message = ""
    Landmark.update_all(old: true)
    line = 2 #Line 1 is the header, start with line 2 in the count
    begin
      missingField = 0
      latInvalid = false
      lngInvalid = false
      CSV.foreach(landmarks_file, {:col_sep => ",", :headers => true}) do |row|

        #Check to see if Name, lat, or lng are blank
        [0,6,7].each do |field|
          if row[field].blank?
            missingField = field + 1
            break
          end
        end

        #Check to see if lat or lng are valid
        if row[6].to_i < -90 || row[6].to_i > 90
          latInvalid = true
        elsif row[7].to_i < -180 || row[7].to_i > 180
            lngInvalid = true
        end

        begin
          #If we have already created this Landmark, don't create it again.
          l = Landmark.create!({
        	  name: row[0],
        	  street_number: row[1],
        	  route: row[2],
        	  city: row[3],
        	  state: row[4],
        	  zip: row[5],
        	  lat: row[6],
        	  lng: row[7],
            old: false
          })
        rescue
          #Found an error, back out all changes and restore previous POIs
          if missingField > 0
            message = 'Error: Column ' + missingField.to_s + ' on row ' + line.to_s + ' of .csv file cannot be blank.'
          elsif latInvalid
            message = 'Error: latitude on row ' + line.to_s + ' of .csv file is invalid.'
          elsif lngInvalid
            message = 'Error: longitude on row ' + line.to_s + ' of .csv file is invalid.'
          else
            message = 'Error: Duplicate landmark found on line ' + line.to_s + ' of .csv file.'
          end
          Rails.logger.info message
          Rails.logger.info 'All changes have been rolled-back and previous Landmarks have been restored'
          Landmark.is_new.delete_all
          Landmark.is_old.update_all(old: false)
          failed = true
          break
        end
        line += 1
      end
    rescue
      failed = true
      message = 'Error Reading File'
      Rails.logger.info message
      Rails.logger.info 'All changes have been rolled-back and previous Landmarks have been restored'
      Landmark.is_new.delete_all
      Landmark.is_old.update_all(old: false)
      failed = true
    end

    if failed
      return false, message
    else
      return true, Landmark.count.to_s + " landmarks loaded"
    end

  end #Update

end #Landmark
