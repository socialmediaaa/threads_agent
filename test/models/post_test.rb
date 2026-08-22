require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @account = ThreadAccount.create!(
      threads_user_id: "999999999",
      username: "poster",
      access_token: "token",
      token_expires_at: 1.hour.from_now
    )
  end

  test "valid with required attributes" do
    post = Post.new(
      thread_account: @account,
      content: "Hello world",
      status: :draft
    )
    assert post.valid?
  end

  test "invalid without thread_account" do
    post = Post.new(content: "Hello", status: :draft)
    assert_not post.valid?
    assert post.errors[:thread_account].present?
  end

  test "invalid without content" do
    post = Post.new(thread_account: @account, status: :draft)
    assert_not post.valid?
    assert post.errors[:content].present?
  end

  test "defaults to draft status" do
    post = Post.new(thread_account: @account, content: "Hello")
    assert post.valid?
    assert post.draft?
  end

  test "status enum works" do
    post = Post.create!(thread_account: @account, content: "Test", status: :draft)
    assert post.draft?
    post.queued!
    assert post.queued?
    post.published!
    assert post.published?
    post.failed!
    assert post.failed?
  end

  test "due scope returns posts with scheduled_at in past" do
    due_post = Post.create!(thread_account: @account, content: "Due", status: :queued, scheduled_at: 1.hour.ago)
    future_post = Post.create!(thread_account: @account, content: "Future", status: :queued, scheduled_at: 1.hour.from_now)
    draft_post = Post.create!(thread_account: @account, content: "Draft", status: :draft, scheduled_at: 1.hour.ago)

    due_posts = Post.due
    assert_includes due_posts, due_post
    assert_not_includes due_posts, future_post
    assert_not_includes due_posts, draft_post
  end

  test "published_at is set when status changes to published" do
    post = Post.create!(thread_account: @account, content: "Test", status: :queued, scheduled_at: 1.hour.ago)
    assert_nil post.published_at
    post.update!(status: :published)
    assert_not_nil post.published_at
  end
end
