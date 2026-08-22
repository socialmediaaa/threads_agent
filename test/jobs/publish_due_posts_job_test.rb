require "test_helper"

class PublishDuePostsJobTest < ActiveSupport::TestCase
  class MockClient
    attr_reader :calls

    def initialize
      @calls = []
      @results = {}
      @errors = {}
      @expected_args = {}
    end

    def expect(method, result, args = nil)
      @results[method] = result
      @expected_args[method] = args
    end

    def raise_error(method, error)
      @errors[method] = error
    end

    def publish_text_post(content)
      @calls << { method: :publish_text_post, content: content }
      if @errors[:publish_text_post]
        raise @errors[:publish_text_post]
      end
      result = @results[:publish_text_post]
      raise "Unexpected call to publish_text_post with content: #{content}" unless result
      result
    end
  end

  test "publishes due queued posts" do
    account = ThreadAccount.create!(
      threads_user_id: "888888888",
      username: "jobuser",
      access_token: "job_token",
      token_expires_at: 1.hour.from_now
    )
    due_post = Post.create!(
      thread_account: account,
      content: "Due post",
      status: :queued,
      scheduled_at: 1.hour.ago
    )

    client = MockClient.new
    client.expect(:publish_text_post, { id: "post_123" }, [ "Due post" ])

    PublishDuePostsJob.new.perform(client: client)

    assert_equal 1, client.calls.size
    assert_equal "Due post", client.calls.first[:content]

    due_post.reload
    assert due_post.published?
    assert_not_nil due_post.published_at
    assert_equal "post_123", due_post.threads_post_id
  end

  test "does not publish future scheduled posts" do
    account = ThreadAccount.create!(
      threads_user_id: "888888889",
      username: "jobuser2",
      access_token: "job_token2",
      token_expires_at: 1.hour.from_now
    )
    Post.create!(
      thread_account: account,
      content: "Future post",
      status: :queued,
      scheduled_at: 1.hour.from_now
    )

    client = MockClient.new
    PublishDuePostsJob.new.perform(client: client)

    assert_empty client.calls
  end

  test "does not publish draft posts" do
    account = ThreadAccount.create!(
      threads_user_id: "888888890",
      username: "jobuser3",
      access_token: "job_token3",
      token_expires_at: 1.hour.from_now
    )
    Post.create!(
      thread_account: account,
      content: "Draft post",
      status: :draft,
      scheduled_at: 1.hour.ago
    )

    client = MockClient.new
    PublishDuePostsJob.new.perform(client: client)

    assert_empty client.calls
  end

  test "does not publish failed posts" do
    account = ThreadAccount.create!(
      threads_user_id: "888888891",
      username: "jobuser4",
      access_token: "job_token4",
      token_expires_at: 1.hour.from_now
    )
    Post.create!(
      thread_account: account,
      content: "Failed post",
      status: :failed,
      scheduled_at: 1.hour.ago
    )

    client = MockClient.new
    PublishDuePostsJob.new.perform(client: client)

    assert_empty client.calls
  end

  test "marks post as failed on API error" do
    account = ThreadAccount.create!(
      threads_user_id: "888888892",
      username: "jobuser5",
      access_token: "job_token5",
      token_expires_at: 1.hour.from_now
    )
    due_post = Post.create!(
      thread_account: account,
      content: "Due post",
      status: :queued,
      scheduled_at: 1.hour.ago
    )

    client = MockClient.new
    client.raise_error(:publish_text_post, ThreadsApi::Error.new("API error"))

    PublishDuePostsJob.new.perform(client: client)

    assert_equal 1, client.calls.size
    due_post.reload
    assert due_post.failed?
    assert_match "API error", due_post.error_message
  end

  test "creates audit log entries" do
    account = ThreadAccount.create!(
      threads_user_id: "888888893",
      username: "jobuser6",
      access_token: "job_token6",
      token_expires_at: 1.hour.from_now
    )
    due_post = Post.create!(
      thread_account: account,
      content: "Due post",
      status: :queued,
      scheduled_at: 1.hour.ago
    )

    client = MockClient.new
    client.expect(:publish_text_post, { id: "post_123" }, [ "Due post" ])

    assert_difference "AuditLog.count", 1 do
      PublishDuePostsJob.new.perform(client: client)
    end

    log = AuditLog.last
    assert_equal "PublishDuePostsJob", log.actor
    assert_equal "publish", log.action
    assert_equal due_post.id, log.post_id
    assert_equal "success", log.details["status"]
  end
end
