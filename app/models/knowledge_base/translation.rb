# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Translation < ApplicationModel
  include HasAgentAllowedParams
  include HasSearchIndexBackend

  AGENT_ALLOWED_ATTRIBUTES = %i[title footer_note kb_locale_id].freeze

  belongs_to :knowledge_base, inverse_of: :translations, touch: true
  belongs_to :kb_locale,      inverse_of: :knowledge_base_translations, class_name: 'KnowledgeBase::Locale'

  validates :title,        presence: true, length: { maximum: 250 }
  validates :kb_locale_id, uniqueness: { case_sensitive: true, scope: :knowledge_base_id }

  def assets(data)
    return data if assets_added_to?(data)

    data = super
    knowledge_base.assets(data)
  end

  def search_index_attribute_lookup(include_references: true)
    attrs = super

    attrs['title'] = ActionController::Base.helpers.strip_tags attrs['title']

    attrs
  end

  scope :search_sql_text_fallback, lambda { |query|
    where_or_cis(%w[title], query)
  }

  scope :apply_kb_scope, lambda { |scope|
    none if scope.present?
  }
end
