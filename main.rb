require 'rubygems'
require 'bigdecimal'
require 'pry'
require 'bundler'
Bundler.setup(:default)
require 'dotenv/load'
require 'bitmex'

Bitmex.configure do |config|
  config.adapter = Faraday.default_adapter
  config.url = 'https://www.bitmex.com'
  config.user_agent = 'Bitmex Ruby Gem'
  # config.loud_logger = true
end
private_client = Bitmex.http_private_client(ENV['BITMEX_API_KEY'], ENV['BITMEX_API_SECRET'])
public_client = Bitmex.http_public_client

FUTURE_SETTLING_ON_CURRENCY_TYPE = 'FFCCSX'.freeze

def to_xbt(amount)
  (BigDecimal(amount, 10) * 0.00000001).to_f
end

def formatted_balance(amount)
  amount.to_s.ljust(11).concat('XBT')
end

def countdown
  puts
  print "\t"
  20.times do |i|
    if (i + 1) % 20 == 0
      print '↓'
    else
      print '»'
    end
    sleep 0.5
  end
end

def safe_response(&request)
  response = nil
  loop do 'Ensuring request is received with 200'
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
latest_expiring_xbt_future = nil

loop do
  system 'clear'
  loop do 'Fetching latest expiring XBT future'
    break if latest_expiring_xbt_future
    puts "\tFinding latest expiring XBT future..."
    this_and_next_year_suffixes = [Time.now.year, Time.now.year + 1].map do |year|
      year.to_s.chars.last(2).join
    end
    xbt_month_futures = safe_response do
      public_client.instrument(filter: { rootSymbol: 'XBT', typ: FUTURE_SETTLING_ON_CURRENCY_TYPE })
    end&.body&.select do |future|
      this_and_next_year_suffixes.include?(future[:symbol].chars.last(2).join)
    end
    if xbt_month_futures&.none?
      puts "\tFailure, retrying..."
      next
    end
    latest_expiring_xbt_future = xbt_month_futures.sort_by do |future|
      Time.new(future[:expiry])
    end.last
    puts "\tSuccess!"
  end
  user_margin_info = safe_response { private_client.user_margin }
  free_balance = to_xbt(user_margin_info.body.fetch(:availableMargin))
  total_amount = to_xbt(user_margin_info.body.fetch(:walletBalance))
  ping_to_bitmex = `ping -c 1 bitmex.com | grep time= | awk '{ print $8 }' | awk -F "=" '{ print $2 }'`
  begin
    puts "\tLooking for position close..."
    if (free_balance == total_amount)
      puts "\tPOSITION CLOSE DETECTED"
      detected_closes += 1
      last_price = safe_response { public_client.instrument({ symbol: latest_expiring_xbt_future[:symbol] }) }.body.first[:lastPrice]
      order_quantity = (free_balance * last_price).round(0) - 10
      safe_response { private_client.create_order(latest_expiring_xbt_future[:symbol], order_quantity, side: 'Sell', ordType: 'Market') }
      safe_response { private_client.position_isolate(latest_expiring_xbt_future[:symbol], false) }
      puts "\tENTERED SHORT x0 WITH WHOLE ACCOUNT"
    else
      puts "\tNot found."
    end
  end
  puts "\t-------------------------------------------"
  puts "\t  Script started at:\t#{script_start_timestamp}"
  puts "\t      Last check at:\t#{Time.now.strftime('%d-%m-%Y %H:%M:%S')}"
  puts "\t    Detected closes:\t#{detected_closes}"
  puts "\t Remaining requests:\t#{user_margin_info.headers['x-ratelimit-remaining']}/#{user_margin_info.headers['x-ratelimit-limit']}"
  puts "\t     Ping to Bitmex:\t#{ping_to_bitmex.chomp} ms"
  puts
  puts "\tFound future symbol:\t#{latest_expiring_xbt_future[:symbol]}"
  puts "\t Future expiry date:\t#{Time.new(latest_expiring_xbt_future[:expiry]).strftime('%d-%m-%Y')}"
  puts
  puts "\t       Free balance:\t#{formatted_balance(free_balance)}"
  puts "\tOn exchange balance:\t#{formatted_balance(total_amount)}"
  countdown
end
