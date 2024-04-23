require 'gpx'
require 'sqlite3'
require 'geocoder'

require './database'


Position = Struct.new(:id, :time, :epoch, :lat, :lng, :altitude, :address)
Event = Struct.new(:id, :time, :epoch, :type, :type_name, :position_id, :position)

Message = Struct.new(:id, :messenger_id, :messenger_name, :unix_time, :message_type, :lat, :lon, :model_id, :show_custom_msg, :date_time, :battery_state, :hidden, :altitude)

# read the sqlite database for events
# divide into waypoints and tracks (unlimited-track)
# consider the OK as a track point 

def generate_gpx(gpx_name, db_name)

  db = SQLite3::Database.open(db_name)
  
  gpx = GPX::GPXFile.new
  track = GPX::Track.new(name: 'route')
  tract_segment = GPX::Segment.new

  db.execute( "select id,unix_time,message_type,lat,lon,altitude from messages order by unix_time" ) do |row|

    location = Geocoder.search( [row[3], row[4]])
    p "#{row[3]}, #{row[4]} - #{location.first.country}"

    # based on type decide if need a waypoint or not
    # if OK or HELP, create waypoint
    tract_segment.points << GPX::TrackPoint.new({lat: row[3], lon: row[4], elevation: row[5], time: Time.at(row[1])})
  end

  track.segments << tract_segment
  gpx.tracks << track
  gpx.write(gpx_name)

end

# initialize database 
# should normally be created already but just in case
db_file = '../data/feed_data.db'
initialize_database(db_file)
seed_database(db_file)

generate_gpx("../data/gpx_files/test.gpx", db_file)
