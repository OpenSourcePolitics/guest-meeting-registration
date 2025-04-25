# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class CancelRegistration < Decidim::Command
      def initialize(registration_request, meeting)
        @registration_request = registration_request
        @meeting = meeting
      end

      def call
        return broadcast(:invalid) if @registration_request.blank?

        @registration_request.destroy
        Decidim::GuestMeetingRegistration::LeaveMeeting.call(meeting, user)
        destroy_follow

        broadcast(:ok)
      rescue StandardError
        broadcast(:invalid)
      end

      private

      attr_reader :meeting, :registration_request

      delegate :user, to: :registration_request, allow_nil: true

      def destroy_follow
        Decidim::DeleteFollow.call(follow_form)
      end

      def follow_form
        Decidim::FollowForm
          .from_params(followable_gid: meeting.to_signed_global_id.to_s)
          .with_context(current_user: user)
      end
    end
  end
end
