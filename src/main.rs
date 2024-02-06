use std::env;
use std::error::Error;
use std::process::exit;
use reqwest;
use quick_xml::Reader;
use quick_xml::events::Event;

// feed
//   feedResponse
//     count
//     feed 
//       id, name, description, status, usage, daysRange, detailedMessageShown, type
//     totalCount
//     activityCount
//     messages
//       message
//         id, messengerId, messengerName, unixTime, messageType, latitude, longitude, dateTime, altitude
//         messageType - OK, TRACK, EXTREME-TRACK, UNLIMITED-TRACK, NEWMOVEMENT, HELP, HELP-CANCEL, CUSTOM, POI, STOP


//   errors
//     error
//       code
//       text
//        description

// enum SpotTags {
//   FeedTag,
//   ErrorTag,
//   ResponseTag,
//   CountTag,
//   StatusTag
// }

#[derive(Debug)]
struct FeedInfo {
  id: String,
  name: String,
  description: String,
  status: String,
  usage: i16,
  days_range: i16,
  detailed_message_shown: bool,
}

#[derive(Debug)]
struct MessageInfo {
  id: String,
  messenger_id: String,
  messenger_name: String,
  unix_time: i64,
  message_type: String,
  latitude: f32,
  longitude: f32,
  altitude: i32,
  model_id: String,
  show_custom_msg: bool,
  date_time: String,
  battery_state: String,
  hidden: bool,
}

// https://api.findmespot.com/spot-main-web/consumer/rest-api/2.0/public/feed/0RWqSn8iuUFnoShnsm7Fjh2LaUslTu2nI/message.xml

fn build_url(feed_id: &str, _page: i16) -> Result<String, Box<dyn Error>> {

  let base_url = "https://api.findmespot.com/spot-main-web/consumer/rest-api/2.0/public/feed/";
  let xml_url = base_url.to_string() + &feed_id + "/message.xml";

  Ok(xml_url)
}

fn main() -> Result<(), Box<dyn Error>> {

  // get the feed ID
  let args: Vec<String> = env::args().collect();
  if args.len() != 2 {
    println!("Usage: findmespot xml-feed-id");
    exit(-1);
  }

  let feed_id = &args[1];
  println!("{}", feed_id);
    
  // build the findmespot url to get the feed
  let xml_url = build_url(feed_id, 1)?;
  
  // request the feed
  let response = reqwest::blocking::get(xml_url)?;
  let xml_content = response.text()?;

  // parse the xml response
  let mut reader = Reader::from_str(&xml_content);
  reader.trim_text(true);

  let mut buf = Vec::new();
  loop {
    match reader.read_event_into(&mut buf) {
      // exit loop when get to end of file
      Ok(Event::Eof) => break,

      Ok(Event::Start(e)) => {
        // if feed - set section = feed
          // can ignore feed for now
          // will map to metadata section of gpx
            // name -> name
            // description -> desc

        // if messages = set section = messages
          // if message = start new message
          // if 
          // message (POI) -> wpt
          // message (OK) -> wpt
            // altitude -> ele
            // unixtime -> time
        match e.name().as_ref() {
          b"message" => {
            // println!("element: {:?}", e);
            println!("----");
            // clear message
          },
          b"messageType" => {
            let txt = reader
            .read_text(e.name());
            println!("type: {}", txt?);
          },
          b"latitude" => {
            let txt = reader
            .read_text(e.name());
            println!("lattitude: {}", txt?);
          },
          b"longitude" => {
            let txt = reader
            .read_text(e.name());
            println!("longitude: {}", txt?);
          },
          b"altitude" => {
            let txt = reader
            .read_text(e.name());
            println!("altitude: {}", txt?);
          },
          b"unixTime" => {
            let txt = reader
            .read_text(e.name());
            println!("unitTime: {}", txt?);
          },
          b"dateTime" => {
            let txt = reader
            .read_text(e.name());
            println!("dateTime: {}", txt?);
          },
          _ => (),
        }
        // println!("element: {:?}", e);
        // dateTime, altitude, lattitude,longitude, unitTime
      },
      // Ok(Event::Text(e)) => {
      //   // println!("value: {:?}",e);
      // },
      Ok(Event::End(_)) => {
          // if message then save message details to vector
      },

      Err(e) => return Err(Box::new(e)),
      // panic!("Error at position {}: {:?}", reader.buffer_position(), e),

      _ => (), // Other events can be ignored
    }
    buf.clear();
  }

  Ok(())
}
