class Post < ApplicationRecord
  belongs_to :thread_account

  enum :status, { draft: 0, queued: 1, published: 2, failed: 3 }, default: :draft

  validates :content, presence: true
  validates :status, presence: true

  scope :due, -> { where(status: :queued).where("scheduled_at <= ?", Time.current) }

  before_save :set_published_at, if: -> { status_changed? && published? }

  private

  def set_published_at
    self.published_at = Time.current
  end
end
