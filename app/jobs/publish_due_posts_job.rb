require_relative "../services/threads_api/client"

class PublishDuePostsJob < ApplicationJob
  queue_as :default

  def perform(client: nil)
    @client = client || ThreadsApi::Client.new(access_token: default_access_token)
    due_posts = Post.due

    due_posts.find_each do |post|
      publish_post(post)
    end
  end

  private

  def publish_post(post)
    result = @client.publish_text_post(post.content)
    post.update!(
      status: :published,
      published_at: Time.current,
      threads_post_id: result[:id]
    )
    create_audit_log(post, "success", result)
  rescue ThreadsApi::Error => e
    post.update!(status: :failed, error_message: e.message)
    create_audit_log(post, "failed", { error: e.message })
  end

  def create_audit_log(post, status, details)
    AuditLog.create!(
      actor: "PublishDuePostsJob",
      action: "publish",
      post: post,
      details: details.merge(status: status)
    )
  end

  def default_access_token
    ThreadAccount.first&.access_token
  end
end
