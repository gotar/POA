class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true

  has_one_attached :file

  validates :file, presence: true
  validates :name, presence: true

  # Returns a relative URL for the attached file.
  # Using `file.url` with the Disk service requires ActiveStorage::Current.url_options
  # (host/protocol), which is not always set in request contexts.
  # A path helper avoids that requirement.
  def file_url
    return nil unless file.attached?

    Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
  end

  def file_path
    file.path if file.attached?
  end

  def content_type
    file.content_type if file.attached?
  end

  def file_size
    file.byte_size if file.attached?
  end

  def image?
    content_type&.start_with?('image/') || false
  end

  def video?
    content_type&.start_with?('video/') || false
  end

  def audio?
    content_type&.start_with?('audio/') || false
  end

  def text?
    content_type&.start_with?('text/') || false
  end
end
