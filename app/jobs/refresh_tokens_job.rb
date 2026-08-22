class RefreshTokensJob < ApplicationJob
  queue_as :default

  def perform
    ThreadAccount.find_each do |account|
      next unless account.token_expired?
      # TODO: Implement token refresh via Meta Graph API
      # For now, just log
      Rails.logger.info "Token expired for account #{account.username} (#{account.threads_user_id})"
    end
  end
end
