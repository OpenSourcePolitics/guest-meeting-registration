# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class CreateRegistration < Decidim::Command
      def initialize(registration_request, meeting)
        @registration_request = registration_request
        @meeting = meeting
      end

      def call
        return broadcast(:invalid) if registration_request.blank?
        return broadcast(:invalid_form) unless registration_form.valid?
        return broadcast(:invalid) unless meeting.registrations_enabled? && meeting.has_available_slots?

        create_user
        add_user_to_request!

        Decidim::GuestMeetingRegistration::JoinMeeting.call(meeting, user, registration_form)

        send_cancellation_link! if enable_cancellation?
        broadcast(:ok)
      end

      private

      attr_reader :user, :registration_request, :meeting

      delegate :session_token, to: :registration_request
      delegate :questionnaire, :organization, :component, :participatory_space, to: :meeting
      delegate :enable_cancellation?, to: :meeting

      def send_cancellation_link!
        Decidim::GuestMeetingRegistration::SendCancellationJob.perform_later(registration_request.id)
      end

      def registration_form
        @registration_form ||= begin
          form_data = registration_request.form_data.with_indifferent_access
          form_data.merge!({ id: registration_request.id })
          form = form_object.from_params(form_data).with_context(form_context)
          form
        end
      end

      def form_object
        @form_object ||= if meeting.registration_form_enabled?
                           Decidim::GuestMeetingRegistration::QuestionnaireForm
                         else
                           Decidim::GuestMeetingRegistration::SimpleForm
                         end
      end

      def add_user_to_request!
        @registration_request.user = @user
        @registration_request.confirmed_at = Time.zone.now
        @registration_request.confirmation_token = nil
        @registration_request.save!
      end

      def form_context
        {
          current_organization: organization,
          current_component: component,
          current_user: registration_request.user,
          current_participatory_space: participatory_space,
          session_token:,
          meeting:
        }
      end

      def create_user
        @user = organization.users.where(email: registration_form.email).first_or_initialize
        return if user.persisted?

        user.email = registration_form.email
        user.name = registration_form.name
        user.nickname = UserBaseEntity.nicknamize(registration_form.name, organization:)
        user.skip_confirmation!
        user.tos_agreement = "1"
        user.password = SecureRandom.hex
        user.notification_settings = { "close_meeting_reminder" => "0" }
        user.notifications_sending_frequency = "real_time"
        user.notification_types = "followed-only"
        user.extended_data.merge!({ attend_meetings: true })

        user.save!
      end
    end
  end
end
