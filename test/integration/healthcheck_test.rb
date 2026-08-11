require "test_helper"

class HealthcheckTest < ActionDispatch::IntegrationTest
  test "healthcheck endpoint responds successfully" do
    get "/healthcheck"

    assert_response :success
  end

  test "healthcheck covers database, migrations, queue, and storage" do
    get "/healthcheck"

    assert_includes response.body, "Database is reachable and answers queries"
    assert_includes response.body, "Database migrations are all applied"
    assert_includes response.body, "Job queue is live"
    assert_includes response.body, "Disk-backed storage is writable"
  end
end
