# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class CreateMeetingRequest < Decidim::Command
      def initialize(meeting, registration_form)
        @meeting = meeting
        @registration_form = registration_form
      end

      def call
        return broadcast(:invalid_form) if registration_form.invalid?
        return broadcast(:invalid) if meeting.on_different_platform?
        return broadcast(:invalid) unless meeting.registrations_enabled? && meeting.has_available_slots?
        return broadcast(:invalid) if Decidim::GuestMeetingRegistration::RegistrationRequest.exists?(meeting: meeting, organization: current_organization,
                                                                                                     email: registration_form.email)

        create_registration_request!

        if enable_registration_confirmation?
          send_email_confirmation!
          broadcast(:confirmation_required)
        else
          Decidim::GuestMeetingRegistration::CreateRegistration.call(registration_request, meeting)
          broadcast(:ok)
        end
      end

      private

      attr_reader :meeting, :registration_form, :registration_request

      delegate :enable_registration_confirmation?, to: :meeting

      def send_email_confirmation!
        registration_request.create_confirmation_code!
        Decidim::GuestMeetingRegistration::SendConfirmationInviteJob.perform_later(registration_request.id, current_locale)
      end

      def create_registration_request!
        @registration_request = Decidim::GuestMeetingRegistration::RegistrationRequest.new
        registration_request.organization = current_organization
        registration_request.meeting = meeting
        registration_request.email = registration_form.email
        registration_request.name = registration_form.name
        registration_request.form_data = registration_form.submitted_params
        registration_request.cancellation_token = SecureRandom.hex
        registration_request.session_token = registration_form.context&.session_token

        registration_request.save!
        registration_request
      end
    end
  end
end
