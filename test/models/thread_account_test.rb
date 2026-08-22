require "test_helper"

class ThreadAccountTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    account = ThreadAccount.new(
      threads_user_id: "123456789",
      username: "testuser",
      access_token: "token_abc",
      token_expires_at: 1.hour.from_now
    )
    assert account.valid?
  end

  test "invalid without threads_user_id" do
    account = ThreadAccount.new(username: "testuser", access_token: "token")
    assert_not account.valid?
    assert account.errors[:threads_user_id].present?
  end

  test "invalid without username" do
    account = ThreadAccount.new(threads_user_id: "123", access_token: "token")
    assert_not account.valid?
    assert account.errors[:username].present?
  end

  test "invalid without access_token" do
    account = ThreadAccount.new(threads_user_id: "123", username: "test")
    assert_not account.valid?
    assert account.errors[:access_token].present?
  end

  test "access_token is encrypted" do
    account = ThreadAccount.create!(
      threads_user_id: "123",
      username: "test",
      access_token: "secret_token",
      token_expires_at: 1.hour.from_now
    )
    raw = ThreadAccount.connection.execute("SELECT access_token FROM thread_accounts WHERE id = #{account.id}").first["access_token"]
    assert_not_equal "secret_token", raw
    assert_equal "secret_token", account.access_token
  end

  test "token_expired? returns true when expired" do
    account = ThreadAccount.new(token_expires_at: 1.hour.ago)
    assert account.token_expired?
  end

  test "token_expired? returns false when not expired" do
    account = ThreadAccount.new(token_expires_at: 1.hour.from_now)
    assert_not account.token_expired?
  end
end
