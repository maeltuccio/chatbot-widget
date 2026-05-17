require "test_helper"

class RackAttackTest < ActiveSupport::TestCase
  setup do
    Rack::Attack.cache.store.clear
  end

  test "throttles widget messages by ip" do
    app = Rack::Attack.new(->(_env) { [200, {}, ["OK"]] })

    30.times do
      status, = app.call(
        Rack::MockRequest.env_for(
          "/widget/messages/stream?agent_token=agent-token",
          method: "POST",
          "REMOTE_ADDR" => "203.0.113.10"
        )
      )

      assert_equal 200, status
    end

    status, = app.call(
      Rack::MockRequest.env_for(
        "/widget/messages/stream",
        method: "POST",
        "REMOTE_ADDR" => "203.0.113.10"
      )
    )

    assert_equal 429, status
  end

  test "throttles signups by ip" do
    app = Rack::Attack.new(->(_env) { [200, {}, ["OK"]] })

    5.times do
      status, = app.call(
        Rack::MockRequest.env_for(
          "/users",
          method: "POST",
          "REMOTE_ADDR" => "203.0.113.11"
        )
      )

      assert_equal 200, status
    end

    status, = app.call(
      Rack::MockRequest.env_for(
        "/users",
        method: "POST",
        "REMOTE_ADDR" => "203.0.113.11"
      )
    )

    assert_equal 429, status
  end
end
