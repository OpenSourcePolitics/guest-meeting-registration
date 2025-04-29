# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class JoinMeetingButtonCell < Decidim::ViewModel
      include Decidim::GuestMeetingRegistration::HasToken

      delegate :enable_guest_registration?, :disable_account_confirmation?, to: :model, prefix: false
      delegate :on_different_platform?, :has_available_slots?, :registration_form_enabled?, :registrations_enabled?, :remaining_slots, to: :model, prefix: false
      delegate :current_user, to: :controller, prefix: false
      delegate_missing_to :controller

      def show
        return original_button if current_user.present?
        return original_button if on_different_platform?
        return original_button unless registrations_enabled?
        return original_button unless enable_guest_registration?

        render
      end

      private

      alias meeting model

      def button_classes
        "button button__xl button__secondary w-full"
      end

      def big_button?
        options[:big_button]
      end

      def i18n_join_text
        return I18n.t("join", scope: "decidim.guest_meeting_registration.join_meeting_button") if has_available_slots?

        I18n.t("no_slots_available", scope: "decidim.meetings.meetings.show")
      end

      def i18n_confirm_text
        I18n.t("confirm", scope: "decidim.meetings.meetings.registration_confirm")
      end

      def i18n_cancel_text
        I18n.t("cancel", scope: "decidim.meetings.meetings.registration_confirm")
      end

      def shows_remaining_slots?
        options[:show_remaining_slots] && model.available_slots.positive?
      end

      def original_button
        cell "decidim/meetings/join_meeting_button", model, **options
      end

      def guest_registration_path
        Decidim::EngineRouter.main_proxy(current_component).decidim_guest_meeting_registration_path(meeting_id: model.id)
      end

      def cancellation_url
        "#{guest_registration_path}/cancellation/#{cancellation_token}"
      end

      def cancellation_token
        @cancellation_token ||= Decidim::GuestMeetingRegistration::RegistrationRequest.where(meeting:, session_token:).first.try(:cancellation_token)
      end
    end
  end
end
