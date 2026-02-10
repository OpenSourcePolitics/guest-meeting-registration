# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class ConfirmController < Decidim::Meetings::ApplicationController
      include Decidim::GuestMeetingRegistration::HasQuestionnaire

      helper_method :show_public_participation?

      def show
        @registration_request = Decidim::GuestMeetingRegistration::RegistrationRequest.where(
          organization: current_organization,
          meeting:,
          confirmation_token: params[:id]
        ).first

        Decidim::GuestMeetingRegistration::CreateRegistration.call(@registration_request, meeting) do
          on(:ok) do
            flash[:notice] = I18n.t("registrations.create.success", scope: "decidim.meetings")
            redirect_to Decidim::EngineRouter.main_proxy(@meeting.component).meeting_path(@meeting)
          end

          on(:invalid) do
            flash[:alert] = I18n.t("registrations.create.invalid", scope: "decidim.meetings")
            redirect_to Decidim::EngineRouter.main_proxy(@meeting.component).meeting_path(@meeting)
          end

          on(:invalid_form) do
            flash[:alert] = I18n.t("response.invalid", scope: "decidim.forms.questionnaires")
            render template:, assigns: { form: registration_form }
          end
        end
      end

      private

      def valid_questionnaire?
        meeting.registration_form_enabled? && questionnaire.present?
      end

      def show_public_participation?
        true
      end
    end
  end
end
