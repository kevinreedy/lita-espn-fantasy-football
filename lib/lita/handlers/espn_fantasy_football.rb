require "nokogiri"
require "terminal-table"

module Lita
  module Handlers
    class EspnFantasyFootball < Handler
      # configs
      config :league_id, required: true
      config :season_id, required: true, default: "2015"

      # routes
      route(/^player\s+(.+)/, :command_player, command: true, help: {
        "player PLAYER NAME" => "Replies information about this football player"
      })

      route(/^scoreboard\s+\(\d*\)/, :command_scoreboard, command: true, help: {
        "scoreboard WEEK" => "Replies with the scoreboard for the specified week. If WEEK is empty, the current scoreboard is returned"
      })

      # chat controllers
      def command_player(response)
        player = response.matches.first.first
        Lita.logger.debug("#{ response.user.name } asked about player #{ player }")

        results = espn_player_search(player)

        if results["rows"].any?
          response.reply(format_results(results))
        else
          response.reply("No results found for '#{ player }'")
        end
      end

      def command_scoreboard(response)
        week = response.matches.first.first
        unless week.empty?
          if week.to_i < 1 or week.to_i > 13
            response.reply("Please specify a week from 1 - 13")
          end
        end

        Lita.logger.debug("#{ response.user.name } requested scoreboard for week '#{ week }'")
        matchups = espn_scoreboard_scrape(week).map do |m|
        table = Terminal::Table.new(:headings => matchsup["headers"], :rows => matchups["rows"])
        response.reply("```\n#{ table }\n```")
      end

      # constants
      ESPN_POSITION_MAP = {
        "qb" => 0,
        "rb" => 2,
        "wr" => 4,
        "te" => 6,
        "flex" => 23,
        "d" => 16,
        "k" => 17
      }

      ESPN_STATUS_MAP = {
        "ir" => "injured",
        "o" => "out",
        "p" => "probable",
        "q" => "questionable",
        "sspd" => "suspended"
      }

      # helper methods
      def get_troll_response
        responses = [
          "Your request was bad and you should feel bad.",
          "Stop wasting my time with your bullshit.",
          "Was that even English?"
        ].sample
      end

      def espn_player_search(query, position="")
        resp = {
          "headers" => [
            "player",
            "team",
            "position",
            "owner",
            "projection",
            "note"
          ],
          "rows" => [],
        }

        url = "http://games.espn.go.com/ffl/freeagency?leagueId=#{ config.league_id }&seasonId=#{ config.season_id }&avail=-1&search=#{ query }"

        if position && ESPN_POSITION_MAP[position]
          url += "&position=#{ ESPN_POSITION_MAP[position] }&slotCategoryId=2"
        end

        Lita.logger.debug("Searching for player at #{ url }")

        page = Nokogiri::HTML(open(url))
        players = page.css("table.playerTableTable.tableBody tr.pncPlayerRow")

        players.each do |p|
          bio_cell = p.css("td.playertablePlayerName")

          # skip blank cells
          next unless bio_cell

          # extract info
          name, bio = bio_cell.text.split(", ")
          chunks = bio.split(/[[:space:]]+/)

          if chunks.length < 2
            Lita.logger.warn("Got a weird cell for player query #{ query }")
            next
          end

          team, position, note = chunks
          note.downcase! if note

          if note
            if ESPN_STATUS_MAP.include?(note)
              note = ESPN_STATUS_MAP[note]
            else
              Lita.logger.warn("Status #{ note } missing from status map")
            end
          end

          owner = p.css("td")[2].text
          proj = p.css("td")[13].text

          resp["rows"] << {
            "player" => name,
            "team" => team,
            "position" => position,
            "owner" => owner,
            "projection" => proj,
            "note" => note
          }

        end

        resp
      end

      def espn_scoreboard_scrape(week)
        resp = {
          "headers" => [
            "team",
            "score"
          ],
          "rows" => []
        }
        params = {
          "leagueId" => config.league_id,
          "seasonId" => config.season_id
        }
        # If no period (aka, week) is specified, ESPN defaults to the
        # most recent (aka, current) matchup period
        unless week.empty?
          params["matchupPeriodId"] = week
        end

        param_string = params.map { |key, val| "#{key}=#{val}" }
        url = "http://games.espn.go.com/ffl/scoreboard?#{param_string}"
        scoreboard = Nokogiri::HTML(open(url))

        matchups = page.css("table.playerTableTable.tableBody tr.pncPlayerRow")
        resp.rows = matchups.map do |m|
          rows = m.css("tr")
          team_top  = rows[0].css("td.team div.name a").text
          team_bottom = rows[1].css("td.team div.name a").text
          score_top  = rows[0].css("td.score").text
          score_bottom = rows[1].css("td.score").text
          {
            "team"  => "#{team_top}\n#{team_bottom}",
            "score" => "#{score_top}\n#{score_bottom}"
          }
        end
        resp
      end

      def format_results(raw)
        rows = raw["rows"].map{|r| r.map{ |k,v| v}}
        table = Terminal::Table.new(:headings => raw["headers"], :rows => rows)
        "```\n#{ table }\n```"
      end

      Lita.register_handler(self)
    end
  end
end
