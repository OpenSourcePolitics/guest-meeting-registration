# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class JoinMeeting < Decidim::Meetings::JoinMeeting
      # Initializes a JoinMeeting Command.
      #
      # meeting - The current instance of the meeting to be joined.
      # user - The user joining the meeting.
      # registration_form - A form object with params; can be a questionnaire.
      def initialize(meeting, user, registration_form)
        @meeting = meeting
        @user = user
        @form = registration_form
      end

      # Creates a meeting registration if the meeting has registrations enabled
      # and there are available slots.
      #
      # Broadcasts :ok if successful, :invalid otherwise.
      def current_user
        @user
      end

      private

      def increment_score; end

      def questionnaire?
        meeting.registration_form_enabled? && @form.model_name == "questionnaire"
      end
    end
  end
end
