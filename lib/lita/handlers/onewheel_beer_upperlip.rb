require 'rest-client'
require 'nokogiri'
require 'sanitize'
require 'lita-onewheel-beer-base'

module Lita
  module Handlers
    class OnewheelBeerUpperlip < OnewheelBeerBase
      route /^upperlip$/i,
            :upperlip_list,
            command: true,
            help: {'upperlip' => 'Display the current taps.'}

      route /^upperlip ([\w ]+)$/i,
            :taps_deets,
            command: true,
            help: {'upperlip 4' => 'Display the tap 4 deets.'}

      route /^upperlip ([<>=\w.\s]+)%$/i,
            :upperlip_by_abv,
            command: true,
            help: {'upperlip >4%' => 'Display beers over 4% ABV.'}

      route /^upperlip (roulette|random)$/i,
            :upperlip_by_random,
            command: true,
            help: {'upperlip roulette' => 'Can\'t decide?  Let me do it for you!'}

      route /^upperliplow$/i,
            :upperlip_by_remaining,
            command: true,
            help: {'upperliplow' => 'Show me the kegs at <10% remaining, or the lowest one available.'}

      route /^upperlipabvlow$/i,
            :upperlip_low_abv,
            command: true,
            help: {'upperlipabvlow' => 'Show me the lowest abv keg.'}

      route /^upperlipabvhigh$/i,
            :upperlip_high_abv,
            command: true,
            help: {'upperlipabvhigh' => 'Show me the highest abv keg.'}

      def upperlip_list(response)
        # wakka wakka
        beers = self.get_source
        reply = "Bailey's Upperlip tap: "
        beers.each do |tap, datum|
          reply += "#{tap}) "
          reply += get_tap_type_text(datum[:type])
          reply += datum[:brewery].to_s + ' '
          reply += (datum[:name].to_s.empty?)? '' : datum[:name].to_s + '  '
        end
        reply = reply.strip.sub /,\s*$/, ''

        Lita.logger.info "Replying with #{reply}"
        response.reply reply
      end

      def send_response(tap, datum, response)
        reply = "Bailey's Upperlip tap #{tap}) #{get_tap_type_text(datum[:type])}"
        reply += "#{datum[:brewery]} "
        reply += "#{datum[:name]} "
        reply += "- #{datum[:desc]}, "
        # reply += "Served in a #{datum[1]['glass']} glass.  "
        reply += "#{datum[:remaining]}"

        Lita.logger.info "send_response: Replying with #{reply}"

        response.reply reply
      end

      def get_source
        # https://visualizeapi.com/api/upperlip
        Lita.logger.debug "get_source started"
        unless (response = redis.get('page_response'))
          Lita.logger.info 'No cached result found, fetching.'
          response = RestClient.get('http://theupperlip.net/draft/')
          redis.setex('page_response', 1800, response)
        end
        # response.gsub! '<div id="responsecontainer"">', ''
        parse_response response
      end

      # This is the worker bee- decoding the html into our "standard" document.
      # Future implementations could simply override this implementation-specific
      # code to help this grow more widely.
      def parse_response(response)
        Lita.logger.debug "parse_response started."
        gimme_what_you_got = {}
        noko = Nokogiri.HTML response
        tap = 0
        noko.css('div#boxfielddata').each do |beer_node|
          # gimme_what_you_got
          tap = tap + 1
          tap_name = get_tap_name(beer_node)

          remaining = beer_node.attributes['title'].to_s

          brewery = get_brewery(beer_node)
          beer_name = beer_node.css('span i').first.children.to_s
          beer_desc = get_beer_desc(beer_node)
          abv = get_abv(beer_desc)
          full_text_search = "#{brewery} #{beer_name} #{beer_desc.to_s.gsub /\d+\.*\d*%*/, ''}"

          gimme_what_you_got[tap] = {
              remaining: remaining,
              brewery: brewery.to_s,
              name: beer_name.to_s,
              desc: beer_desc.to_s,
              abv: abv.to_f,
              search: full_text_search
          }
        end
        gimme_what_you_got
      end

      def get_abv(beer_desc)
        if (abv_matches = beer_desc.match(/\d+\.\d+%/))
          abv_matches.to_s.sub '%', ''
        end
      end

      # Return the desc of the beer, "Amber ale 6.9%"
      def get_beer_desc(noko)
        beer_desc = ''
        if (beer_desc_matchdata = noko.to_s.gsub(/\n/, '').match(/(<br\s*\/*>)(.+%) /))
          beer_desc = beer_desc_matchdata[2].gsub(/\s+/, ' ').strip
        end
        beer_desc
      end

      # Get the brewery from the node, return it or blank.
      def get_brewery(noko)
        brewery = ''
        if (node = noko.css('span a').first)
          brewery = node.children.to_s.gsub(/\n/, '')
          brewery.gsub! /RBBA/, ''
          brewery.strip!
        end
        brewery
      end

      # Returns 1, 2, Cask 3, Nitro 4...
      def get_tap_name(noko)
        noko.css('span').first.children.to_s
      end

      Lita.register_handler(self)
    end
  end
end
