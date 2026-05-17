require "test_helper"

class RegistrationsDisabledTest < ActionDispatch::IntegrationTest
  test "public signup routes are disabled" do
    get "/users/sign_up"

    assert_response :not_found

    assert_no_difference "User.count" do
      post "/users", params: {
        user: {
          account_name: "Pilot Workspace",
          email: "pilot@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :not_found
  end
end
