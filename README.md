# bitmex_cash_keeper
A bot automatically entering short x0 with whole account when all positions are closed to keep cash.

Tested on ruby 2.6.1

# Usage
1. Run `bundle install`
2. Copy `.env.example` to `.env` and fill api key and secret
3. Run `ruby main.rb`
You also may want to point to fixed commit (instead of master) here: https://github.com/dominikduda/bitmex_cash_keeper/blob/master/Gemfile#L3

Notice that you shouldn't really run this with a real account because this may be api key and secret steal attempt.
