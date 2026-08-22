require "test_helper"

account = ThreadAccount.create!(
  threads_user_id: "888888888",
  username: "jobuser",
  access_token: "job_token",
  token_expires_at: 1.hour.from_now
)

due = Post.create!(thread_account: account, content: "Due", status: :queued, scheduled_at: 1.hour.ago)
future = Post.create!(thread_account: account, content: "Future", status: :queued, scheduled_at: 1.hour.from_now)
draft = Post.create!(thread_account: account, content: "Draft", status: :draft, scheduled_at: 1.hour.ago)
failed = Post.create!(thread_account: account, content: "Failed", status: :failed, scheduled_at: 1.hour.ago)

puts "Due posts:"
Post.due.each { |p| puts "  #{p.content} (status=#{p.status}, scheduled=#{p.scheduled_at})" }
