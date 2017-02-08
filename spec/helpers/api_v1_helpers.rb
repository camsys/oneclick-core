module Api::V1::Helpers

  # Signs in user via api and returns their auth token
  def api_sign_in user
    post :create, params: {
      "user": {
          "email": user.email,
          "password": user.password
        }
    }, as: :json
    return JSON.parse(response.body)
  end

  def auth_token user
    return api_sign_in(user)["authentication_token"]
  end
end
