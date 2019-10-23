# frozen_string_literal: true

module LockerHelpers
  def remove_models(*models)
    models.each do |model|
      Object.send :remove_const, model.to_s.to_sym
    end

    Mongoid.models.clear
  end
end
