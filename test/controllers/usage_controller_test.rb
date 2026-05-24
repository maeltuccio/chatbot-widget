require "test_helper"
require "csv"

class UsageControllerTest < ActionDispatch::IntegrationTest
  test "usage page does not expose limit form" do
    user = users(:one)
    sign_in user

    get usage_url

    assert_response :success
    refute_includes response.body, "Définir les limites"
    refute_includes response.body, "Enregistrer les limites"
  end

  test "exports current month billable usage as csv" do
    account = accounts(:one)
    agent = agents(:one)
    UsageEvent.create!(
      account: account,
      agent: agent,
      event_type: "message",
      model: "gpt-4o-mini",
      input_tokens: 10,
      output_tokens: 20,
      input_characters: 40,
      output_characters: 80,
      metadata: { estimated_tokens: false }
    )
    sign_in users(:one)

    get usage_url(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    csv = CSV.parse(response.body, headers: true)
    assert_equal 1, csv.length
    assert_equal agent.name, csv.first["agent"]
    assert_equal "message", csv.first["type"]
    assert_equal "gpt-4o-mini", csv.first["modele"]
    assert_equal "30", csv.first["tokens_total"]
  end
end
