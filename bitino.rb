#!/usr/bin/env ruby

###############################
# BILLmanager Ticket Notifier #
#         (BiTiNo)            #
###############################
#      file: bitino.rb        #
###############################

## Load required gems:
#  To work with HTTP:
require 'net/http'
#  To parse BILLmanager's APIs:
require 'nokogiri'
#  To read config file:
require 'yaml'
#  To show nice desktop notifications:
require 'libnotify'

## Load config file:
CONFIG = YAML.load_file "#{ENV['HOME']}/.config/isp.conf"

puts "#{__FILE__}"

## Declare Ticket class to extract tickets from XML more easily:
class Ticket
  attr_reader :id, :name, :client, :unread, :blocked, :deadline
  def initialize(xml_ticket)
    @id = xml_ticket.search(".//ticket").inner_text
    @name = xml_ticket.search(".//name").inner_text
    @client = xml_ticket.search(".//client").inner_text
    @unread = xml_ticket.search(".//unread").inner_text === "on" ? true : false
    @blocked = xml_ticket.search(".//blocked_by").size > 0 ? true : false
    @deadline = xml_ticket.search(".//deadline").inner_text
  end
end

## Authenticate and get a session ID:
def billmgr_auth()
  ## Try to auth with given credentials get the session ID:
  auth_data = Nokogiri::XML(
    Net::HTTP.get URI( "%{billmgr}?out=xml&func=auth&username=%{user}&password=%{pass}" % CONFIG )
  )
  ## Now form the API endpoint URL:
  auth_id = auth_data.search('/doc/auth').first['id']
  api_url = "%{billmgr}?out=xml&auth=%{auth_id}" % CONFIG.merge({ auth_id: auth_id })
  ## And return it to the caller:
  api_url
end

## Get ticket data:
def get_tickets(api_url)
  tickets_raw = Nokogiri::XML((Net::HTTP.get URI("%s&func=ticket" % api_url)
                              ).force_encoding('UTF-8'))
  ## Load tickets from XML into new instances of Ticket class,
  ## and return the array of Ticket objects as a result.
  tickets_raw.search('/doc/elem').map { |ticket| Ticket.new(ticket) }
end

## Authenticate in BILLmanager:
api_url = billmgr_auth

## Loop it!
loop do
  ## Now get client ticket list:
  tickets = get_tickets(api_url)

  ## Extract unread and blocked tickets:
  unread_tickets = tickets.select{ |ticket| ticket.unread and not ticket.blocked }

  ## Fire a libnotify event for every unread ticket:
  unread_tickets.each do |unread_ticket|
    Libnotify.show(
      summary: "BILLmgr: %d/%d" % [ unread_tickets.size, tickets.size ],
      body: "%s: %s\n%s" % [ unread_ticket.id, unread_ticket.client, unread_ticket.name ],
      timeout: 3,
      transient: true,
      append: true
    )
  end
  Kernel.sleep 15
  GC.start
end
