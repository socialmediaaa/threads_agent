class ThreadAccount < ApplicationRecord
  encrypts :access_token

  validates :threads_user_id, presence: true, uniqueness: true
  validates :username, presence: true
  validates :access_token, presence: true

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end
end
