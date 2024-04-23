require 'dotenv/load'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'sqlite3'

require './database'

# TODO: select feed_url_id, feed_password from users inner join feeds on users.email == 'athir@nuaimi.com'

# for a given feed, query the findmespot api for events & process by putting into sqlite3 database

## NOTES:  
#     if change request to .json, can get json back
#     message type: OK, TRACK, EXTREME-TRACK, UNLIMITED-TRACK,
#                   NEWMOVEMENT, 
#                   HELP, HELP-CANCEL, 
#                   CUSTOM, POI, STOP

Feed = Struct.new(:id, :name, :description, :status, :usage, :days_range, :detailed_message_shown, :type)
Message = Struct.new(:id, :messenger_id, :messenger_name, :unix_time, :message_type, :lat, :lon, :model_id, :show_custom_msg, :date_time, :battery_state, :hidden, :altitude)

def process_response( response, db)

  # see if we got an error
  errors = response.xpath('//response/errors/error')
  if errors.empty?
    response = response.xpath('//response/feedMessageResponse')
    puts "received data"
    parse_messages(response, db)
  else
    # API call didn't work
    puts "received error response"
    parse_errors(errors, db)
  end
  
end

def parse_messages(response, db)

  # where do these get logged?

  count = response.xpath('count').text
  total_count = response.xpath('totalCount').text
  activity_count = response.xpath('activityCount').text

  feed = Feed.new
  feed_info = response.xpath('feed')
  feed.id = feed_info.at_xpath('id').text
  feed.name = feed_info.at_xpath('name').text
  feed.description = feed_info.at_xpath('description').text
  feed.status = feed_info.at_xpath('status').text
  feed.usage = feed_info.at_xpath('usage').text
  feed.days_range = feed_info.at_xpath('daysRange').text
  feed.detailed_message_shown = feed_info.at_xpath('detailedMessageShown').text
  feed.type = feed_info.at_xpath('type').text

  puts "#{count} messages for #{feed.id}"

  messages = Array.new
  
  messages_info = response.xpath('messages/message')
  messages_info.each do | message_info|
  
    message = Message.new
    message.id = message_info.at_xpath('id').text
    message.messenger_id = message_info.at_xpath('messengerId').text
    message.messenger_name = message_info.at_xpath('messengerName').text
    message.unix_time = message_info.at_xpath('unixTime').text
    message.message_type = message_info.at_xpath('messageType').text
    message.lat = message_info.at_xpath('latitude').text
    message.lon = message_info.at_xpath('longitude').text
    message.model_id = message_info.at_xpath('modelId').text
    message.show_custom_msg = message_info.at_xpath('showCustomMsg').text
    message.date_time = message_info.at_xpath('dateTime').text
    message.battery_state = message_info.at_xpath('batteryState').text
    message.hidden = message_info.at_xpath('hidden').text
    message.altitude = message_info.at_xpath('altitude').text
  
    # puts "id: #{message.id} type:#{message.message_type}"

    messages << message
  end

  count = 0
  messages.each do |message|

    # save message to database
    begin
      updated_at = Time.now
      statement = "INSERT OR REPLACE INTO messages (id, messanger_id, messanger_name, unix_time, message_type, lat, lon, model_id, 
                    show_custom_msg, date_time, battery_state, hidden, altitude, updated_at)
      VALUES('#{message.id}', '#{message.messenger_id}', '#{message.messenger_name}',#{message.unix_time}, '#{message.message_type}', 
              #{message.lat}, #{message.lon}, '#{message.model_id}', '#{message.show_custom_msg}', '#{message.date_time}', '#{message.battery_state}', 
              #{message.hidden}, #{message.altitude}, #{updated_at.to_r})" 
      # puts statement
      db.execute(statement)
      count +=1

    rescue SQLite3::BusyException => e
      puts "database in use by another app"   
    end

  end

  puts "inserted #{count} rows of data"
  log_msg = "inserted #{count} rows of data from spot"
  updated_at = Time.now
  sql_statement = "INSERT INTO logs (text, updated_at) VALUES ('#{log_msg}', #{updated_at.to_r})"
  db.execute(sql_statement)

end

def parse_errors(errors, db)

  errors.each do |error|
    code = error.at_xpath('code').text
    text = error.at_xpath('text').text
    description = error.at_xpath('description').text
    puts "code: #{code} (#{text})"

    # possible errors
    #   E-0160: invalid feed
    #   E-0195: no messsages to display

    # save error to database
    updated_at = Time.now
    begin
      statement = "INSERT INTO logs (code, text, description, updated_at) VALUES('#{code}', '#{text}', '#{description}', #{updated_at.to_r})" 
      puts statement
      db.execute(statement)
    rescue SQLite3::BusyException => e
      puts "database in use by another app"      
    end
  end

end

# get the xml feed from Spot
def get_xml_feed( feed_id)

  feed_url = "https://api.findmespot.com/spot-main-web/consumer/rest-api/2.0/public/feed/#{feed_id}/message.xml"

  uri = URI(feed_url)
  res = Net::HTTP.get_response(uri)

  if res.is_a?(Net::HTTPSuccess)
    return res.body
  elsif res.is_a?(Net::HTTPTooManyRequests)
    # 429 error spot will return if query more than every 2.5min
    puts "error: being throttled by Spot"
    return nil
  else
    puts "error: #{e.message}"
    return nil
  end
end

def main
  # process file or loop of feeds

# initialize database
# should normally already be created already (but just in case)
data_path = "../data/"
db_file = data_path + 'feed_data.db'
initialize_database(db_file)

#seed_database(db_file)

db = SQLite3::Database.open(db_file)

# get the xml feed and process any messages in it
clean_up = false
loop do 

  # get the xml feed from spot
  feed_id = ENV['FEED_ID']
  puts "feed_id: #{feed_id}"

  xml_string = get_xml_feed(feed_id)

  data_path = "../data/spot_files/"
  # file = data_path + 'message-0220.xml'
  file = data_path + 'message-0301.xml'
  # file = data_path + 'message-0310.xml'
  # file = data_path + 'message-good.xml'
  # file = data_path + 'message-error2.xml'
  xml_string = File.read(file)

  # parse the response
  begin
    response = Nokogiri::XML(xml_string)
  rescue Exception => e
    puts e.message
  end
  process_response(response, db)

  clean_up = true

  # NOT MORE FREQUENTLY THEN EVERY 2.5 min otherwise get a http error 429
  # if have multiple feeds, space 2 sec apart (from same host/client)
  # sleep 150

  break if clean_up == true
end

end

# START HERE

main

