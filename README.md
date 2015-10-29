# lita-espn-fantasy-football

[![Build Status](https://travis-ci.org/kevinreedy/lita-espn-fantasy-football.png?branch=master)](https://travis-ci.org/kevinreedy/lita-espn-fantasy-football)
[![Coverage Status](https://coveralls.io/repos/kevinreedy/lita-espn-fantasy-football/badge.png)](https://coveralls.io/r/kevinreedy/lita-espn-fantasy-football)

This handler is used to scrape data from ESPN's Fantasy Football Site. Right now, it is very limited, so PRs are very welcome!

## Installation

Add lita-espn-fantasy-football to your Lita instance's Gemfile:

``` ruby
gem "lita-espn-fantasy-football"
```

## Configuration

Set your `league_id`, and optionally `season_id` (defaults to 2015)

```ruby
Lita.configure do |config|
  config.handlers.espn_fantasy_football.league_id = "123456"
  config.handlers.espn_fantasy_football.season_id = "2015"
end
```

## Usage

### Searching for a Player

Search for a player by last name

```
Lita: player manning

+------------------+------+----------+-------+------------+------+
| player           | team | position | owner | projection | note |
+------------------+------+----------+-------+------------+------+
| Peyton Manning   | Den  | QB       | RG3   | 17         |      |
| Eli Manning      | NYG  | QB       | CALI  | 17         |      |
| Mario Manningham | NYG  | WR       | FA    | --         |      |
+------------------+------+----------+-------+------------+------+
```

### Checking the scoreboard

Get this week's scoreboard

```
Lita: score

+-------------------------------+-------+
| team                          | score |
+-------------------------------+-------+
| The Prime Rib Special         | 66    |
| Wouldn't it be great if I won | 147   |
|                               |       |
| Genghis is my real name       | 60    |
| Miles is a better real name   | 104   |
|                               |       |
| Is Keith still alive?         | 71    |
| Minnesota State Faircatch     | 108   |
|                               |       |
+-------------------------------+-------+
```

Get any week's scoreboard

```
Lita: score 3

+-------------------------------+-------+
| team                          | score |
+-------------------------------+-------+
| Is Keith still alive?         | 72    |
| Miles is a better real name   | 71    |
|                               |       |
| Genghis is my real name       | 97    |
| Wouldn't it be great if I won | 62    |
|                               |       |
| The Prime Rib Special         | 119   |
| Minnesota State Faircatch     | 107   |
|                               |       |
+-------------------------------+-------+
```
