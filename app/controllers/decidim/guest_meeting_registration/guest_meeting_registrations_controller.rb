# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class GuestMeetingRegistrationsController < Decidim::Meetings::ApplicationController
      include Decidim::Forms::Concerns::HasQuestionnaire
      include Decidim::GuestMeetingRegistration::HasQuestionnaire

      def create
        @form = form_object.from_model(questionnaire)
        render template: template
      end

      def answer
        @form = form_object.from_params(params, session_token: session_token, meeting: meeting)

        Decidim::GuestMeetingRegistration::CreateMeetingRequest.call(meeting, @form) do
          on(:confirmation_required) do
            flash[:notice] = I18n.t("registrations.create.confirmation_required", scope: "decidim.meetings")
            redirect_to after_answer_path
          end

          on(:ok) do
            flash[:notice] = I18n.t("registrations.create.success", scope: "decidim.meetings")
            redirect_to after_answer_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("registrations.create.invalid", scope: "decidim.meetings")
            render template: template
          end

          on(:invalid_form) do
            flash.now[:alert] = I18n.t("answer.invalid", scope: i18n_flashes_scope)
            render template: template
          end
        end
      end

      private

      def form_object
        @form_object ||= if valid_questionnaire?
                           form(Decidim::GuestMeetingRegistration::QuestionnaireForm)
                         else
                           form(Decidim::GuestMeetingRegistration::SimpleForm)
                         end
      end

      def valid_questionnaire?
        meeting.registration_form_enabled? && questionnaire.present?
      end

      def after_answer_path
        form_path
      end

      def allow_unregistered?
        meeting.enable_guest_registration?
      end

      def allow_answers?
        meeting.registrations_enabled? && meeting.registration_form_enabled? && meeting.has_available_slots?
      end

      def questionnaire_for
        meeting
      end

      def meeting
        @meeting ||= Decidim::Meetings::Meeting.where(component: current_component).find(params[:meeting_id])
      end
    end
  end
end
