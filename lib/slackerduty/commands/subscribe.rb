# frozen_string_literal: true

require_relative '../slack_responder'

module Slackerduty
  module Commands
    class Subscribe
      include SlackResponder

      def execute
        linked_user_only do
          policy_id = args.first

          policy =
            Slackerduty::PagerDutyApi
            .escalation_policy(policy_id)
            .body
            .fetch('escalation_policy')

          Models::Subscription.find_or_create_by!(
            user_id: @user.id,
            escalation_policy_id: policy['id']
          )

          @payload = Slack::BlockKit::Composition::Mrkdwn.new(
            text: <<~MESSAGE
              You've subscribed to receive notification on the following escalation policy: #{policy['summary']}.
              `/slackerduty unsub #{policy['id']}` to unsubscribe.
            MESSAGE
          )

          respond
        end
      rescue Faraday::ResourceNotFound
        @payload = Slack::BlockKit::Composition::Mrkdwn.new(
          text: <<~MESSAGE
            I couldn't find that escalation policy.
            `/slackerduty policies` to view all escalation policies.
          MESSAGE
        )

        respond
      end
    end
  end
end
