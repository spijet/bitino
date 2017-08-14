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
CONFIG = YAML.load_file(ENV['HOME'] + '/.config/isp.conf')

## Declare Ticket class to extract tickets from XML more easily:
class Ticket
  attr_reader :id, :name, :client, :unread, :blocked, :mine, :deadline

  def initialize(xml_ticket)
    @id = xml_ticket.search('.//ticket').inner_text
    @name = xml_ticket.search('.//name').inner_text
    @client = xml_ticket.search('.//client').inner_text
    @unread = xml_ticket.search('.//unread').inner_text == 'on' ? true : false
    @blocked = !xml_ticket.search('.//blocked_by').empty? ? true : false
    @mine = !xml_ticket.search('.//blocked_by_me').empty? ? true : false
    @deadline = xml_ticket.search('.//deadline').inner_text
  end
end

## Authenticate and get a session ID:
def billmgr_auth
  ## Prepare BILLmanager auth URI:
  auth_uri = URI.parse(CONFIG['billmgr'])
  auth_uri.query = URI.encode_www_form(out: 'xml', func: 'auth',
                                       username: CONFIG['user'],
                                       password: CONFIG['pass'])

  ## Try to auth with given credentials get the session ID:
  auth_data = Nokogiri::XML(Net::HTTP.get(auth_uri))
  ## Now form the API endpoint URI:
  auth_id = auth_data.search('/doc/auth').first['id']
  #  Clone auth URI and change the params:
  api_uri = auth_uri.dup
  api_uri.query = URI.encode_www_form(out: 'xml', func: 'ticket',
                                      auth: auth_id)
  ## And return it to the caller:
  api_uri
end

## Get ticket data:
def get_tickets(api_uri)
  tickets_raw = Nokogiri::XML(
    Net::HTTP.get(api_uri).force_encoding('UTF-8')
  )
  ## Load tickets from XML into new instances of Ticket class,
  ## and return the array of Ticket objects as a result.
  tickets_raw.search('/doc/elem').map { |ticket| Ticket.new(ticket) }
end

## Authenticate in BILLmanager:
api_uri = billmgr_auth

## Loop it!
loop do
  ## Now get client ticket list:
  tickets = get_tickets(api_uri)

  ## Extract unread and blocked tickets:
  unread_tickets = tickets.select do |ticket|
    ticket.unread && !(ticket.blocked ^ ticket.mine)
  end

  ## Fire a libnotify event for every unread ticket:
  unread_tickets.each do |unread_ticket|
    Libnotify.show(
      summary: format('BILLmgr: %d/%d', unread_tickets.size, tickets.size),
      body: format('%s: %s\n%s',
                   unread_ticket.id, unread_ticket.client, unread_ticket.name),
      timeout: 3,
      transient: true,
      append: true
    )
  end
  Kernel.sleep 15
  GC.start
end
