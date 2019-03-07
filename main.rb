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


loop do
  puts Time.now.strftime('%d-%m-%Y %H:%M:%S')
  response = private_client.user_margin
  puts "Available requests limit: #{response.headers['x-ratelimit-remaining']}/#{response.headers['x-ratelimit-limit']}"
  user_margin = response.body
  free_balance = to_xbt(user_margin.fetch(:availableMargin))
  total_amount = to_xbt(user_margin.fetch(:walletBalance))
  if (free_balance == total_amount)
    puts "POSITION CLOSE DETECTED"
    loop do
      last_price = public_client.instrument({ symbol: 'XBTUSD' }).body.first[:lastPrice]
      order_quantity = (free_balance * last_price).round(0) - 10
      response = private_client.create_order('XBTUSD', order_quantity, side: 'Sell', ordType: 'Market')
      next if response.status != 200
      break
    end
    loop do
      response = private_client.position_isolate('XBTUSD', false)
      next if response.status != 200
      break
    end
    puts "ENTERED SHORT x0 WITH WHOLE ACCOUNT"
  end

  puts '------------'
  puts "       Free balance:\t#{formatted_balance(free_balance)}"
  puts "On exchange balance:\t#{formatted_balance(total_amount)}"
  puts '*******************************'
  sleep 10
end
