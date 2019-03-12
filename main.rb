require 'rubygems'
require 'bigdecimal'
require 'pry'
require 'bundler'
Bundler.setup(:default)
require 'dotenv/load'
require 'bitmex'

Bitmex.configure do |config|
  config.adapter = Faraday.default_adapter # default: Faraday.default_adapter
  config.url = 'https://www.bitmex.com' # default: https://www.bitmex.com
  config.user_agent = 'Bitmex Ruby Gem' # default: 'Bitmex Ruby Gem [Gem Version]'
  # config.loud_logger = true # default false
end
private_client = Bitmex.http_private_client(ENV['BITMEX_API_KEY'], ENV['BITMEX_API_SECRET'])
public_client = Bitmex.http_public_client

def to_xbt(amount)
  (BigDecimal(amount, 10) * 0.00000001).to_f
end

def formatted_balance(amount)
  amount.to_s.ljust(11).concat('XBT')
end

def countdown
  puts "\t--------------------"
  print "\t"
  10.times { |i| print 10 - i; print ' '; sleep 1  }
end

def safe_response(&request)
  response = nil
  loop do
    begin
      response = request.call
    rescue BitmexError => error
      puts "\tThere was an error:"
      puts error
      sleep 3
      next
    rescue Faraday::ConnectionFailed
      puts "\tCould not connect to Bitmex"
      sleep 3
      next
    end
    return response if response&.status == 200
  end
end

script_start_timestamp = Time.now.strftime('%d-%m-%Y %H:%M:%S')
detected_closes = 0

loop do
  system 'clear'
  puts "\t  Script started at:\t#{script_start_timestamp}"
  puts "\t    Detected closes:\t#{detected_closes}"
  puts
  user_margin_info = safe_response { private_client.user_margin }
  free_balance = to_xbt(user_margin_info.body.fetch(:availableMargin))
  total_amount = to_xbt(user_margin_info.body.fetch(:walletBalance))
  if (free_balance == total_amount)
    puts "\tPOSITION CLOSE DETECTED"
    detected_closes += 1
    last_price = safe_response { public_client.instrument({ symbol: 'XBTUSD' }) }.body.first[:lastPrice]
    order_quantity = (free_balance * last_price).round(0) - 10
    safe_response { private_client.create_order('XBTUSD', order_quantity, side: 'Sell', ordType: 'Market') }
    safe_response { private_client.position_isolate('XBTUSD', false) }
    puts "\tENTERED SHORT x0 WITH WHOLE ACCOUNT"
  end
  puts "\t      Last check at:\t#{Time.now.strftime('%d-%m-%Y %H:%M:%S')}"
  puts "\t Remaining requests:\t#{user_margin_info.headers['x-ratelimit-remaining']}/#{user_margin_info.headers['x-ratelimit-limit']}"
  puts "\t       Free balance:\t#{formatted_balance(free_balance)}"
  puts "\tOn exchange balance:\t#{formatted_balance(total_amount)}"
  countdown
end
