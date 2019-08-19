# frozen_string_literal: true

module Inferno
  module Models
    class ResourceReference
      include DataMapper::Resource
      property :id, String, key: true, default: proc { SecureRandom.uuid }
      property :resource_type, String
      property :resource_id, String
      property :profile, String

      belongs_to :testing_instance
    end
  end
end
