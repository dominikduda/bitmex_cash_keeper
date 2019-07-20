# bitmex_cash_keeper
A bot automatically shorting x0 (cross margin/isolated position) with whole account when all positions are closed.
The shorted instrument is XBT month future, because it has no funding (to avoid funding)
Shorting with cross margin freezes your money because such position is literally 'synthetic USD'.

Google for "Bitmex synthetic usd" for more info.

Tested on ruby 2.6.1

# Usage
1. Run `bundle install`
2. Copy `.env.example` to `.env` and fill your Bitmex api key and secret
3. Run `ruby main.rb`
You also may want to point to fixed commit (instead of master) here: https://github.com/dominikduda/bitmex_cash_keeper/blob/master/Gemfile#L3
