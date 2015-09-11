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

      def format_results(raw)
        rows = raw["rows"].map{|r| r.map{ |k,v| v}}
        table = Terminal::Table.new(:headings => raw["headers"], :rows => rows)
        "```\n#{ table }\n```"
      end

      Lita.register_handler(self)
    end
  end
end
