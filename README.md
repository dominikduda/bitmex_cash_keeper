# bitmex_cash_keeper
A bot automatically shorting x0 (cross margin/isolated position) with whole account when all positions are closed.
The shorted instrument is XBT month future, because it has no funding (to avoid funding)

Shorting with cross margin freezes your money because such position is literally 'synthetic USD'. It is possible because technical magic of [Bitmex contracts](https://www.bitmex.com/app/perpetualContractsGuide).

Google for "Bitmex synthetic USD" for more info about this mechanic.

# Usage
1. Run `bundle install`
2. Copy `.env.example` to `.env` and fill your Bitmex api key and secret
3. Run `ruby main.rb`
You also may want to point to fixed commit (instead of latest master) for [my Bitmex api gem](https://github.com/dominikduda/bitmex_cash_keeper/blob/master/Gemfile#L3).

Tested on ruby 2.6.1

### Output screenshot:
![output](https://raw.githubusercontent.com/dominikduda/bitmex_cash_keeper/master/bitmex_cash_keeper_output.png)
