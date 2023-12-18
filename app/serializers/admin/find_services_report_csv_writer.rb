module Admin
  class FindServicesReportCSVWriter < CSVWriter

    # Find Services report table will include the following columns:
    #
    # Date and time of search			          The date and time when user navigates to Find Services sub-sub-category page e.g. "3/1/2022  11:43:11 AM"
    # User name			                        The traveler username e.g. "guest_163957735915@example.com"
    # User type			                        The user type - 211 Ride Staff User, Public User or Guest
    # User IP Address			                  The traveler user's IP address when accessing the site e.g. "130.44.180.166"
    # User starting location			          The user's location address entered in the Your Location field on the Find Human Services & Resources Near You page e.g. "Ventura, CA"
    # Service sub-sub-category searched			The sub-sub-category that the user clicks on to navigate to the Find Services services list page e.g. "Congregate Meal/Nutrition Sites"
    # Trip ID			                          If a trip was planned through the Find Transportation to this Service button based on the service search, include the Trip ID. Otherwise this is blank.
    columns :created_at,
              :traveler, :user_type, :traveler_ip,
              :user_starting_location,
              :service_sub_sub_category, :trip_id

    def traveler
      @record.user && @record.user&.email
    end

    def user_type
      if @record.user&.admin_or_staff? == true
        'Staff User'
        # NOTE: the below translations are 211 Ride specific and have values that are not the same
        # as the fallback value, nor are they values that you'd generally expect
      elsif @record.user&.guest? == true
        I18n.t('admin.reporting.guest') ||'Guest'
      elsif @record.user&.registered_traveler?
        I18n.t('admin.reporting.public_user') || 'Public User'
      else
        ''
      end
    end

    def traveler_ip
      @record.user_ip
    end

  end
end
