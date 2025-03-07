# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Template < ApplicationModel
  include ChecksClientNotification
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include Template::Assets
  include Template::TriggersSubscriptions

  scope :active, -> { where(active: true) }

  store     :options
  validates :name, presence: true

  association_attributes_ignored :user
end
