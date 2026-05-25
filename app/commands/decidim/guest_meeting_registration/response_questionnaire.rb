# frozen_string_literal: true

module Decidim
  module GuestMeetingRegistration
    class ResponseQuestionnaire < Decidim::Forms::ResponseQuestionnaire
      # Initializes a AnswerQuestionnaire Command.
      #
      # form - The form from which to get the data.
      # questionnaire - The current instance of the questionnaire to be answered.
      def initialize(form, questionnaire, current_user = nil)
        @form = form
        @questionnaire = questionnaire
        @current_user = current_user
      end

      private

      def response_questionnaire
        @main_form = @form
        @errors = nil

        Decidim::Forms::Response.transaction(requires_new: true) do
          form.responses_by_step.flatten.select(&:display_conditions_fulfilled?).each do |form_response|
            response = Decidim::Forms::Response.new(
              user: current_user || @current_user,
              questionnaire: @questionnaire,
              question: form_response.question,
              body: form_response.body,
              session_token: form.context.session_token,
              ip_hash: form.context.ip_hash
            )

            build_choices(response, form_response)

            response.save!

            next unless form_response.question.has_attachments?

            # The attachments module expects `@form` to be the form with the
            # attachments
            @form = form_response
            @attached_to = response

            build_attachments

            if attachments_invalid?
              @errors = true
              next
            end

            create_attachments if process_attachments?
            document_cleanup!
          end

          @form = @main_form
          raise ActiveRecord::Rollback if @errors
        end
      end
    end
  end
end
