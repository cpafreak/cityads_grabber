#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'

require 'nokogiri'
require 'csv'

unless ARGV.length == 2
    puts "Dude, not the right number of arguments."
    puts "Usage: ruby cityads.rb login password\n"
    exit
end

a = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

a.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

offers_array = Array.new

nick = ARGV[0]
pswd = ARGV[1]
a.get('https://cityads.ru/') do |page|

  my_page = page.form_with(:action => 'https://cityads.ru/action.php') do |f|
    f.nick  = nick
    f.passwd  = pswd
  end.click_button


  spisok_offerov = a.click(my_page.link_with(:href => "/ru/webmaster/offeryi/spisok_offerov_175.0.htm"))
  table = Nokogiri::HTML(spisok_offerov.body)

  rows = table.css('tr.even, tr.odd')

  rows.each do |row|

    action_id = row.css('.action_id').text.strip

    cpl = row.css('.ppa').text.strip
    cpc = row.css('.sppa').text.strip

    category = row.css('.category_name').text.strip

    locked_img = row.css('.locked img')[0]['src']

    if locked_img.include?('unlocked')
      locked = false
    else
      locked = true
    end

    action_name = row.css('.action_name a')
    action_name_href = action_name[0]['href']
    action_name_name = action_name.text.strip

    #puts action_name_href
    #puts action_name_name
    #puts action_id, locked, cpl, cpc, category

    if !locked
      a.get('https://cityads.ru%s?show_promo=links' % action_name_href  ) do |offer_page|
        offer = Nokogiri::HTML(offer_page.body)

        link = offer.css('.mandatory')[0].content

        offers_array << [ action_id, action_name_name, cpl, cpc, category, link ]
        puts action_name_name
        puts link
      end
    end


  end

end

offers_array << ["ID", "NAME", "CPL", "CPC", "CATEGORY", "LINK"]
CSV.open('cityads.csv', 'w') do |writer|

  offers_array.reverse.each do |offer|
    writer << offer
  end

  puts "CSV done"
end