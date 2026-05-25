# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    module HasQuestionnaire
      extend ActiveSupport::Concern

      included do
        include FormFactory
        include Decidim::GuestMeetingRegistration::HasToken

        helper_method :visitor_already_responded?, :meeting, :update_url, :form_path
        invisible_captcha on_spam: :spam_detected

        def form_path
          Decidim::EngineRouter.main_proxy(current_component).meeting_path(meeting)
        end

        def meeting
          @meeting ||= Decidim::Meetings::Meeting.where(component: current_component).find(params[:meeting_id])
        end

        def template
          if valid_questionnaire?
            "decidim/guest_meeting_registration/questionnaires/show"
          else
            "decidim/guest_meeting_registration/questionnaires/simplified"
          end
        end

        # You can implement this method in your controller to change the URL
        # where the questionnaire will be submitted.
        def update_url
          "#{form_path}/guest-registration/answer"
        end
      end
    end
  end
end
