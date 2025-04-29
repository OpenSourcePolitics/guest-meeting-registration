# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class SimpleForm < Decidim::Form
      include ActiveModel::Validations::Callbacks
      delegate :meeting, to: :context

      attribute :email
      attribute :name
      attribute :public_participation, Boolean, default: false

      attribute :tos_agreement, Boolean

      before_validation :before_validation

      validates :tos_agreement, allow_nil: false, acceptance: true
      validates :name, presence: true
      validates :email, presence: true, "valid_email_2/email": { disposable: true }
      validate :meeting_input

      def initialize(attributes = {})
        @submitted_params = attributes.deep_symbolize_keys.slice(:email, :name, :public_participation, :tos_agreement)

        super
      end

      attr_reader :submitted_params

      private

      def meeting_input
        errors.add(:email, :taken) if Decidim::GuestMeetingRegistration::RegistrationRequest.where.not(id:).exists?(
          meeting:,
          organization: current_organization,
          email:
        )
      end

      # Add other responses to the context so AnswerForm can validate conditional questions
      def before_validation
        context.responses = attributes[:responses]
      end
    end
  end
end
