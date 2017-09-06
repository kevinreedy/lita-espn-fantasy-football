require 'nokogiri'
require 'terminal-table'
require 'open-uri'

module Lita
  module Handlers
    # Lita Handler for scraping ESPN's Fantasy Football site
    class EspnFantasyFootball < Handler
      # configs
      config :league_id, required: true
      config :season_id, default: '2017'
      config :activity_room
      config :activity_interval, default: 60 * 15 # Fifteen minutes

      on :connected, :activity_timer

      # routes
      route(/^player\s+(.+)/, :command_player, command: true, help: {
              'player PLAYER NAME' => 'Replies information about this football player'
            })

      route(/^score(board)*\s*(\d*)/, :command_scoreboard, command: true, help: {
              'score WEEK' => 'Replies with the scoreboard for the specified week. If WEEK is empty, the current scoreboard is returned'
            })

      route(/^activity/, :command_activity, command: true, help: {
              'activity' => 'Replies with the latest league activity. This automatically runs every 15 minutes by default.'
            })

      # chat controllers
      def command_player(response)
        player = response.matches.first.first
        Lita.logger.debug("#{response.user.name} asked about player #{player}")

        results = espn_player_search(player)

        if results['rows'].any?
          response.reply(format_results(results))
        else
          response.reply("No results found for '#{player}'")
        end
      end

      def command_scoreboard(response)
        week = response.matches.first[1]
        Lita.logger.debug("#{response.user.name} requested scoreboard for week '#{week}'")

        if week.empty? || (week.to_i >= 1 && week.to_i <= 13)
          matchups = espn_scoreboard_scrape(week)
          response.reply(format_results(matchups))
        else
          response.reply('Please specify a week from 1 - 13')
        end
      end

      def command_activity(response)
        # Get last activity from redis or default to start of season
        since = DateTime.parse(redis.get('espn_fantasy_football_last_activity')) rescue DateTime.new(config.season_id.to_i)
        activity = espn_activity_scrape(since)

        if activity && activity.any?
          response.reply(espn_activity_scrape(since))
        else
          response.reply("No new activity since #{since.to_time}")
        end
      end

      def activity_timer(_response)
        Lita.logger.debug('Setting up activity_timer')

        # If config.activity_room wasn't specified, do not set timer
        return unless config.activity_room

        # If config.activity_interval is 0, do not set timer
        return if config.activity_interval.zero?

        every(config.activity_interval) do
          Lita.logger.debug('Running activity_timer')

          # Get last activity from redis or default to start of season
          since = DateTime.parse(redis.get('espn_fantasy_football_last_activity')) rescue DateTime.new(config.season_id.to_i)
          activity = espn_activity_scrape(since)

          if activity && activity.any?
            robot.send_message(Source.new(room: config.activity_room), activity)
          else
            Lita.logger.debug('No new activity found')
          end
        end
      end

      # constants
      ESPN_POSITION_MAP = {
        'qb' => 0,
        'rb' => 2,
        'wr' => 4,
        'te' => 6,
        'flex' => 23,
        'd' => 16,
        'k' => 17
      }.freeze

      ESPN_STATUS_MAP = {
        'ir' => 'injured',
        'o' => 'out',
        'p' => 'probable',
        'q' => 'questionable',
        'sspd' => 'suspended'
      }.freeze

      # helper methods
      def troll_response
        [
          'Your request was bad and you should feel bad.',
          'Stop wasting my time with your bullshit.',
          'Was that even English?'
        ].sample
      end

      def espn_player_search(query, position = '')
        resp = {
          'headers' => %w[
            player
            team
            position
            owner
            projection
            note
          ],
          'rows' => []
        }

        url = "http://games.espn.go.com/ffl/freeagency?leagueId=#{config.league_id}&seasonId=#{config.season_id}&avail=-1&search=#{query}"

        if position && ESPN_POSITION_MAP[position]
          url += "&position=#{ESPN_POSITION_MAP[position]}&slotCategoryId=2"
        end

        Lita.logger.debug("Searching for player at #{url}")

        page = Nokogiri::HTML(open(url))
        players = page.css('table.playerTableTable.tableBody tr.pncPlayerRow')

        players.each do |p|
          bio_cell = p.css('td.playertablePlayerName')

          # skip blank cells
          next unless bio_cell

          # extract info
          name, bio = bio_cell.text.split(', ')
          chunks = bio.split(/[[:space:]]+/)

          if chunks.length < 2
            Lita.logger.warn("Got a weird cell for player query #{query}")
            next
          end

          team, position, note = chunks
          note.downcase! if note

          if note
            if ESPN_STATUS_MAP.include?(note)
              note = ESPN_STATUS_MAP[note]
            else
              Lita.logger.warn("Status #{note} missing from status map")
            end
          end

          owner = p.css('td')[2].text
          proj = p.css('td')[13].text

          resp['rows'] << {
            'player' => name,
            'team' => team,
            'position' => position,
            'owner' => owner,
            'projection' => proj,
            'note' => note
          }
        end

        resp
      end

      def espn_scoreboard_scrape(week)
        resp = {
          'headers' => %w[
            team
            score
          ],
          'rows' => []
        }

        params = {
          'leagueId' => config.league_id,
          'seasonId' => config.season_id
        }

        # If no period (aka, week) is specified, ESPN defaults to the
        # most recent (aka, current) matchup period
        params['matchupPeriodId'] = week unless week.empty?

        param_string = params.map { |key, val| "#{key}=#{val}" }.join('&')
        url = "http://games.espn.go.com/ffl/scoreboard?#{param_string}"
        Lita.logger.debug("Searching for score at #{url}")

        page = Nokogiri::HTML(open(url))
        matchups = page.xpath('//*[@class="ptsBased matchup"]')

        resp['rows'] = matchups.map do |m|
          rows = m.css('tr')
          team_top = rows[0].css('td.team div.name a').text
          team_bottom = rows[1].css('td.team div.name a').text
          score_top = rows[0].css('td.score').text
          score_bottom = rows[1].css('td.score').text

          {
            'team'  => "#{team_top}\n#{team_bottom}\n ",
            'score' => "#{score_top}\n#{score_bottom}\n "
          }
        end

        resp
      end

      def espn_activity_scrape(since = DateTime.new(config.season_id.to_i))
        resp = []
        params = {
          'leagueId' => config.league_id,
          'seasonId' => config.season_id
        }

        param_string = params.map { |key, val| "#{key}=#{val}" }.join('&')
        url = "http://games.espn.go.com/ffl/recentactivity?#{param_string}"
        Lita.logger.debug("Searching for league activity at #{url}")
        page = Nokogiri::HTML(open(url))

        # get activity and remove header rows
        activity = page.xpath('//*[@class="games-fullcol games-fullcol-extramargin"]/table/tr').drop(2)

        activity.each do |a|
          # Parse timestamp
          timestamp = DateTime.parse("#{a.css('td')[0].children[0].text} #{a.css('td')[0].children[2].text}")

          # Exit loop if we've passed the datetime passed into method
          break if timestamp <= since

          type = a.css('td')[1].children[1].text
          subtype = a.css('td')[1].children[4].text
          detail = a.css('td')[2].inner_html
                    .delete('*') # remove asterisks, as they'll conflict with markdown
                    .gsub(%r{<(/)?b>}, '*') # convert bold formatting
                    .gsub(/<br>/, "\n") # convert breaks to newlines
          events = detail.split("\n")

          # add emoji
          if type == 'LM Changed League Settings'
            events.map! { |ev| ":gear: #{ev}" }
          elsif type == 'Transaction'
            events.map! do |ev|
              ev.gsub(/(\S+\sadded)/, ':green_heart: \\1')
                .gsub(/(\S+\sdropped)/, ':broken_heart: \\1')
                .gsub(/(\S+\straded)/, ':revolving_hearts: \\1')
                .gsub(/(\S+\sdrafted)/, ':heavy_plus_sign: \\1')
            end
          end

          resp << events.join("\n")

          # Update redis timestamp if newer than latest activity
          latest_activity = DateTime.parse(redis.get('espn_fantasy_football_last_activity')) rescue DateTime.new(config.season_id.to_i)
          redis.set('espn_fantasy_football_last_activity', timestamp.to_s) if timestamp > latest_activity
        end

        resp
      end

      def format_results(raw)
        rows = raw['rows'].map { |r| r.map { |_k, v| v } }
        table = Terminal::Table.new(headings: raw['headers'], rows: rows)
        "```\n#{table}\n```"
      end

      Lita.register_handler(self)
    end
  end
end
