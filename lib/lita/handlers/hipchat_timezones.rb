module Lita
  module Handlers
    class HipchatTimezones < Handler

      CACHE_KEY = "timezone"

      # Default Configuration
      def self.default_config(config)
        config.enabled  = true
      end

      # Routes
      route /^(timezone|tz)\s+(.+)/, :timezone_cli, command: true

      # Commands
      def timezone_cli(response)
        command = response.args.shift
        case command
          when /@(\w+)/
            fetch_user_timezone(command, response)
          else
            send(command, reponse, *args) if respond_to?(command)
        end
      end

      def fetch_user_timezone(user, response)
        response.reply "#{user}'s timezone is #{fetch_timezone(user)}" 
      end

      private

      def cache_key(user)
        "#{user}_#{CACHE_KEY}"
      end

      def fetch_timezone(user)
        fetch_timezone_from_cache(user) || fetch_timezone_from_hipchat(user)
      end

      def fetch_timezone_from_cache(user)
        redis.get(cache_key(user))
      end

      def fetch_timezone_from_hipchat(user)
        binding.pry
        response = HTTParty.get("https://api.hipchat.com/v2/user/#{user}?auth_token=#{config.token}")
        if response.parsed_response.has_key? "error"
          "unknown :("
        else
          tz = ActiveSupport::TimeZone[ response.parsed_response['timezone'] ]
          tz = "GMT#{tz.formatted_offset[0..2].to_i}"
          redis.set(cache_key(user), tz)
          redis.expire(cache_key(user), 1.month.seconds)
          tz
        end
      end

    end

    Lita.register_handler(HipchatTimezones)
  end
end
