require 'json'
require 'gpx'

# process a JSON data file from the maps section of the findmespot website

Position = Struct.new(:id, :time, :epoch, :lat, :lng, :altitude, :address)
Event = Struct.new(:id, :time, :epoch, :type, :type_name, :position_id, :position)

class SpotData
  
  def initialize
    @positions = Array.new()
    @events = Array.new()
  end

  def load(filename)
    file_contents = File.read("../data/"+filename)
    data = JSON.parse(file_contents)

    positions = data['d']['Assets'][0]['Positions']
    puts "loaded #{positions.length} positions"

    positions.each do |item| 
      # since Spot has newest positions at the end, we need to reverse array
      position = Position.new(item["Id"], item["Time"], item["Epoch"], item["Lat"], item["Lng"], item["Altitude"], item["Address"]);
      @positions.prepend(position)
    end

    # looks like events are not totally in correct order
    # sort by epoch
    @positions.sort_by(&:epoch)

    # now do events

    events = data['d']['Events']
    puts "loaded #{events.length} events"

    events.each do |item|
      event = Event.new(item["Id"], item["Time"], item["Epoch"], item["Type"], item["TypeName"],  item["PositionId"])
      if event.position_id
        # need to fill in the lat lon altitude
        position = find_desired_position(event.position_id)
        event.position = position
      end

      @events.append(event)
    end

    # looks like events are not totally in correct order
    # sort by epoch
    @events.sort_by(&:epoch)

  end

  # def load_events(filename)

  #   # load json file into array
  #   file_contents = File.read("../data/"+filename)
  #   data = JSON.parse(file_contents)
  #   puts "loaded #{data.length} events from #{filename}"

  #   events = Array.new()
  #   data.each do |item|

  #     event = Event.new(item["Id"], item["Time"], item["Epoch"], item["Type"], item["TypeName"],  item["PositionId"])

  #     if event.position_id
  #       # need to fill in the lat lon altitude
  #       position = find_desired_position(event.position_id)
  #       event.lat = position.lat
  #       event.lon = position.lon
  #       event.elevation = position.elevation
  #     end

  #     @events.append(event)
  #   end

  #   # looks like events are not totally in correct order
  #   # sort by epoch
  #   @events.sort_by(&:epoch)

  # end

  # def load_positions(filename)

  #   # load json file into array
  #   file_contents = File.read("../data/"+filename)
  #   data = JSON.parse(file_contents)
  #   puts "loaded #{data.length} positions from #{filename}"

  # # for each item, extra key data
  #   data.each do |item| 
  #     # since Spot has newest positions at the end, we need to reverse array
  #     position = Position.new(item["Id"], item["Time"], item["Epoch"], item["Lat"], item["Lng"], item["Altitude"], item["Address"]);
  #     @positions.prepend(position)
  #   end

  #   # looks like events are not totally in correct order
  #   # sort by epoch
  #   @positions.sort_by(&:epoch)

  # end

  def generate_gpx(filename)

    # assume the data is sorted by epoch

    # create gpx file
    gpx = GPX::GPXFile.new
    
    save_track(gpx)
    # save_waypoints(gpx)

    gpx.write(filename)

    puts("generated #{filename}")

  end

  def save_track(gpx_file)

    # save track & track segments
    positions_len = @positions.length

    last_month = last_day = nil

    segments = Array.new
    segment = Array.new

    # go through all positions (in reverse order)
    # split into segments by date
    track = GPX::Track.new(name: 'route')
    for idx in 0..positions_len-1 do

      # get position
      point = @positions[idx]
      
      # add point to current segment
      segment << point

      # get point's timestamp 
      time = Time.at(point.epoch)
      month = time.month
      day = time.day
      # puts "#{month}-#{day}"

      # decide which segment it goes in
      # see if the same date as last point (position)
      if last_month && ((last_month != month) || (last_day!= day))
        # has a differnt date, 
        # save current segment
        segments << segment

        # start a new one
        segment = Array.new
        segment << point
      end

      # update date
      last_month = month
      last_day = day

    end
    segments << segment

    # add it all to the gpx file
    segments.each do |segment|

      point = segment.first
      # puts point.time

      tract_segment = GPX::Segment.new
      segment.each do |item|
        tract_segment.points << GPX::TrackPoint.new({lat: item.lat, lon: item.lng, elevation: item.altitude, time: Time.at(item.epoch)})
      end
      track.segments << tract_segment

    end
    gpx_file.tracks << track
  
  end

  # return position that has 
  def find_desired_position(id)
    @positions.each do |position|
    
      if id == position.id
        return position
      end

    end

    return nil
  end
  
  def save_waypoints(gpx_file)
    
    # now add waypoints
    @events.each do |event| 

      # see type is 'check in/ok'
      if event.type == 15

        # need to get position details for event
        # use ID to find in array of positions
        position = find_desired_position(event.position_id)

        # create a waypoint and save to gpx file
        waypoint = GPX::Waypoint.new
        waypoint.name = position.time
        waypoint.lat = position.lat
        waypoint.lon = position.lng
        waypoint.elevation = position.altitude
        gpx_file.waypoints << waypoint

      end
    end

  end
end


## Start 

# read filename
# generate output filename
# THEN GO WORK ON XML file

data_path = "../data/"
spot_data = SpotData.new
spot_data.load(data_path + "spot_files/" + "map-data-0301.js")
# spot_data.load_positions("positions-0104-0318.json")
# spot_data.load_events("events-0104-0318.json")
spot_data.generate_gpx(data_path + "gpx_files/" + "map-data-0301.gpx")
