module Admin
  class UsersReportCSVWriter < CSVWriter
    
    columns :email, :first_name, :last_name, :eligibilities, :accommodations
    
    def eligibilities(user)
      user.confirmed_eligibilities.pluck(:code).join(', ')
    end
    
    def accommodations(user)
      user.accommodations.pluck(:code).join(', ')
    end

  end
end
