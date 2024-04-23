require 'gpx'
# require 'sqlite3'
require 'geocoder'

SearchConditions = Struct.new( :countries, :min_date, :max_date)

class GpxInfo 
  attr_accessor :routes, :tracks, :waypoints, :first_date, :last_date, :bounding_box, :countries
  
  def pp
    puts "file has #{@routes} routes, #{@tracks} tracks and #{@waypoints} waypoints"
  end

end


def analyse_gpx_file(filename, search_conditions)

  gpx =  GPX::GPXFile.new(:gpx_file => filename) 
  
  gpx.tracks.each do |track|

    puts "track has #{track.points.size} points & #{track.segments.size} segments"
  
    segments = track.segments
    segments.each do |segment|
      puts "  segment has #{segment.points.size} points"
  
      last_timestamp = nil
      segment.points.each do |point|
  
        # date
        # country
  
        point_timestamp = Time.at(point.time).to_datetime
  
        is_same_day = false
        if last_timestamp 
  
          if ((point_timestamp.year == last_timestamp.year) &&
            (point_timestamp.month == last_timestamp.month) && 
            (point_timestamp.day == last_timestamp.day))
            is_same_day = true
          end
        end
      
        location = Geocoder.search( [point.lat, point.lon])
        if !is_same_day
          p "    #{point_timestamp}: #{point.lat}, #{point.lon} - #{location.first.country}"
        else
          # p "    #{point_timestamp}: #{point.lat}, #{point.lon} - #{location.first.country} ignored"
        end
    
        last_timestamp = point_timestamp
      end
      
    end
  end
  
end

# start here

def summarize_gpx(filename)

  gpx_info = GpxInfo.new

  gpx =  GPX::GPXFile.new(:gpx_file => filename) 
  gpx_info.routes = gpx.routes.count
  gpx_info.tracks = gpx.tracks.count
  gpx_info.waypoints = gpx.waypoints.count
  
  # # of waypoints
  # # of tracks and segments
  # # of routes
  # countries included
  # date range 

  return gpx_info
end

gpx_filename = "../data/gpx_files/map-data-0301.gpx"
if File.file?(gpx_filename)
  gpx_info = summarize_gpx(gpx_filename)
  puts gpx_info.pp
else
  puts "error: file does not exist"
end

# search_conditions = SearchConditions.new( ["Mexico"], nil, nil)
# search_conditions = SearchConditions.new( nil, nil, nil)
# analyse_gpx_file( gpx_filename, search_conditions)




