module Lita
  module Handlers
    class HipchatTimezones < Handler

      CACHE_KEY = "timezone"

      # Default Configuration
      def self.default_config(config)
        config.enabled  = true
      end

      # Routes
      route /^tz\s+(.+)/, :fetch_user_timezone, command: true
      route /^whenis\s+(.+)/, :fetch_user_time, command: true

      def fetch_user_time(response)
        return unless config.enabled
        begin
          user = "@#{response.user.mention_name}"
          # Get stuff
          time, target = *response.args
          # Calculate the remote time
          target_time  = fetch_time(user, time, target)
          # Respond
          response.reply "#{user} your #{time} is #{format_time(target_time)} for #{target}"
        rescue StandardError => e
          # Excuse
          response.reply "Sorry, I failed :("
        end
      end

      def fetch_time(user, time, target)
        # Fetch the timezones
        tz_user   = ActiveSupport::TimeZone[ fetch_timezone(user)   ]
        tz_target = ActiveSupport::TimeZone[ fetch_timezone(target) ]
        # Check that we have them
        raise "Nope" unless tz_user && tz_target
        Time.zone = tz_user
        # Parse the time locally
        user_time = time == "now" ? Time.zone.now : Time.zone.parse(time)
        # Move the time to the target's tz
        target_time = user_time.in_time_zone(tz_target)
      end

      def fetch_user_timezone(response)
        return unless config.enabled
        user = response.args.shift
        response.reply "#{user}'s timezone is #{format_timezone(fetch_timezone(user))}"
      end

      private

      def cache_key(user)
        "#{user}_#{CACHE_KEY}"
      end

      def fetch_timezone(user)
        fetch_timezone_from_cache(user) || fetch_timezone_from_hipchat(user)
      end

      def format_timezone(timezone)
        tz = ActiveSupport::TimeZone[ timezone ]
        "GMT#{tz.formatted_offset[0..2].to_i}"
      end

      def format_time(time)
        time.strftime("%I:%M%P")
      end

      def fetch_timezone_from_cache(user)
        redis.get(cache_key(user))
      end

      def fetch_timezone_from_hipchat(user)
        response = HTTParty.get("https://api.hipchat.com/v2/user/#{user}?auth_token=#{config.token}")
        if response.parsed_response.has_key? "error"
          "unknown :("
        else
          tz = response.parsed_response['timezone']
          redis.set(cache_key(user), tz)
          redis.expire(cache_key(user), 1.month.seconds)
          tz
        end
      end

    end

    Lita.register_handler(HipchatTimezones)
  end
end
