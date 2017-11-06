FactoryBot.define do
  factory :role do
    
    factory :admin_role do
      name "admin"
      resource_type nil
      resource_id nil
    end
    
    factory :staff_role do
      name "staff"
      resource_type nil
      resource_id nil
    end
    
  end
end
