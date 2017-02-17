FactoryGirl.define do
  factory :config do
    key "test_config"
    value "test"

    factory :bool_config do
      key "bool_config"
      value true
    end

    factory :array_config do
      key "array_config"
      value [1,"b",:c]
    end

    factory :num_config do
      key "num_config"
      value 3.1415
    end
  end
end
