module Api::V1::Helpers

  # # Signs in user via api and returns their auth token
  # def api_sign_in user
  #   post :create, params: {
  #     "user": {
  #         "email": user.email,
  #         "password": user.password
  #       }
  #   }, as: :json
  #   return JSON.parse(response.body)
  # end
  #
  # def auth_token user
  #   puts "AUTH TOKEN FOR: ",user.ai
  #   response = api_sign_in(user)
  #   puts response.ai
  #   return response["authentication_token"]
  # end
end
