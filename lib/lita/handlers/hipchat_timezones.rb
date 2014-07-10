module Lita
  module Handlers
    class HipchatTimezones < Handler

      # Default Configuration
      def self.default_config(config)
        config.enabled  = true
      end

      # Routes
      route /^(timezone|tz)\s(@\w+)$/, command: true, :fetch_user_timezone
      route /^(timezone|tz)\s+(.+)/,   command: true, :timezone_cli

      # Commands
      def timezone_cli(response)
        command = args.shift
        send(command, reponse, *args) if respond_to?(command)
      end

      def fetch_user_timezone(response)
        user = args.shift
        response.reply fetch_timezone(user)
      end

      private

      def fetch_timezone(user)

      end

    end

    Lita.register_handler(HipchatTimezones)
  end
end
