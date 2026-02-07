# frozen_string_literal: true

module Colorable
  extend ActiveSupport::Concern

  COLORS = %w[#8B5CF6 #EC4899 #10B981 #F59E0B #3B82F6 #EF4444 #06B6D4 #84CC16].freeze

  included do
    validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, allow_blank: true }
  end

  def ensure_color!
    update!(color: self.class::COLORS.sample) unless color.present?
  end
end