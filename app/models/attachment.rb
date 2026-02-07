class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true

  has_one_attached :file

  validates :file, presence: true
  validates :name, presence: true

  def file_url
    file.url if file.attached?
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
