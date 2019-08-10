<img src="https://raw.githubusercontent.com/dominikduda/config_files/master/dd_logo_blue_bg.png" width="300" height="300" />

# bitmex_cash_keeper
A bot automatically x1.00 with whole account when all positions are closed.
The shorted instrument is XBT month future, because it has no funding which you would have to pay few times a day on any other instrument.

Shorting with leverage x1.00 freezes your money because such position is literally like borrowing (you owe) `N` units of XBT then selling it instantly.
You could say that you are `N` XBT long and `N` XBT short so this is fully hedged position.

Read more about Bitmex contracts [here](https://www.bitmex.com/app/perpetualContractsGuide).

# Usage
1. Run `bundle install`
2. Copy `.env.example` to `.env` and fill your Bitmex api key and secret
3. Run `ruby main.rb`
4. You also may want to point to fixed commit (instead of latest master) for [my Bitmex api gem](https://github.com/dominikduda/bitmex_cash_keeper/blob/master/Gemfile#L3).

Tested on ruby 2.6.1

### Output screenshot:
![output](https://raw.githubusercontent.com/dominikduda/bitmex_cash_keeper/master/bitmex_cash_keeper_output.png)

