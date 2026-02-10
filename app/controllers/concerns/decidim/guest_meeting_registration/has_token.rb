# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    module HasToken
      extend ActiveSupport::Concern

      included do
        def questionnaire
          @questionnaire ||= Decidim::Forms::Questionnaire.includes(questions: :response_options).find_by(questionnaire_for: meeting)
        end

        def valid_questionnaire?
          meeting.registration_form_enabled? && questionnaire.present?
        end

        def visitor_already_responded?
          if valid_questionnaire?
            questionnaire.responded_by?(current_user || session_token)
          else
            Decidim::GuestMeetingRegistration::RegistrationRequest.exists?(meeting:, session_token:)
          end
        end

        def tokenize(id, length: 10)
          tokenizer = if valid_questionnaire?
                        Decidim::Tokenizer.new(salt: questionnaire.salt || questionnaire.id, length:)
                      else
                        Decidim::Tokenizer.new(salt: meeting.id.to_s, length:)
                      end
          tokenizer.int_digest(id).to_s
        end

        # token is used as a substitute of user_id if unregistered
        def session_token
          id = current_user&.id
          session_id = request.session[:session_id] if request&.session

          return nil unless id || session_id

          @session_token ||= tokenize(id || session_id)
        end
      end
    end
  end
end
