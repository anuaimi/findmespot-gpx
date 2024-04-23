use std::env;
use std::error::Error;
use std::process::exit;
use std::fs::File;
use std::io::BufWriter;
use reqwest;
use quick_xml::Reader;
use quick_xml::events::Event;

// use gpx::{Gpx, GpxVersion, Track, TrackSegment, Waypoint};

//   errors
//     error
//       code
//       text
//        description

#[derive(Debug,Default)]
struct FeedInfo {
  id: String,
  name: String,
  description: String,
  status: String,
  usage: i16,
  days_range: i16,
  detailed_message_shown: bool,
  r#type: String,
}

#[derive(Debug,Default)]
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
  show_custom_msg: String,
  date_time: String,
  battery_state: String,
  hidden: String,
}

#[derive(Debug,Default)]
struct ParsedInfo {
  feed_info: FeedInfo,
  messages: Vec<MessageInfo>,
}

// get the spot xml feed ID we should process
fn get_feed_id( ) -> String {

    // get the feed ID from the command line
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
      println!("Usage: findmespot xml-feed-id");
      exit(-1);
    }
    let feed_id = String::from(&args[1]);
  
    return feed_id;
}

// build the url to access the spot xml feed
fn build_url(feed_id: &str, _page: i16) -> Result<String, Box<dyn Error>> {

  let base_url = "https://api.findmespot.com/spot-main-web/consumer/rest-api/2.0/public/feed/";
  let xml_url = base_url.to_string() + &feed_id + "/message.xml";

  Ok(xml_url)
}

fn parse_response(xml_content: String) -> Result<(ParsedInfo), Box<dyn Error>> {

  // parse the xml response
  let mut reader = Reader::from_str(&xml_content);
  reader.trim_text(true);

  let mut section: Option<&str> = None;
  let mut parsed_info = ParsedInfo::new();
  parsed_info.feed_info = FeedInfo{..Default::default()};
  parsed_info.messages = vec![MessageInfo];
  
  let mut message_info = MessageInfo{..Default::default()};

  let mut buf = Vec::new();

  loop {
    match reader.read_event_into(&mut buf) {

      // exit loop when get to end of file
      Ok(Event::Eof) => break,

      Ok(Event::Start(e)) => {

        match section {
          Some("feed") => {

            // get text for tag
            let txt = reader
            .read_text(e.name()).unwrap();

            // assign to struct
            match e.name().as_ref() {
              b"id" => feed_info.id = txt.into(),
              b"name" => feed_info.name = txt.into(),
              b"description" => feed_info.description = txt.into(),
              b"status" => feed_info.status = txt.into(),
              b"usage" => feed_info.usage = txt.parse::<i16>().unwrap(),
              b"daysRange" => feed_info.days_range = txt.parse::<i16>().unwrap(),
              b"detailedMessageShown" => feed_info.detailed_message_shown = txt.parse::<bool>().unwrap(),
              b"type" => feed_info.r#type = txt.into(),
              _ => (),
            }
          },
          Some("message") => {

            // get text for tag
            let txt = reader
            .read_text(e.name()).unwrap();

            match e.name().as_ref() {
              b"id" => message_info.id = txt.into(),
              b"messengerId" => message_info.messenger_id = txt.into(),
              b"messengerName" => message_info.messenger_name = txt.into(),
              b"unixTime" => message_info.unix_time = txt.parse::<i64>().unwrap(),
              b"messageType" => message_info.message_type = txt.into(),
              b"latitude" => message_info.latitude = txt.parse::<f32>().unwrap(),
              b"longitude" => message_info.longitude = txt.parse::<f32>().unwrap(),
              b"altitude" => message_info.altitude = txt.parse::<i32>().unwrap(),
              b"modelId" => message_info.model_id = txt.into(),
              b"showCustomMsg" => message_info.show_custom_msg = txt.into(),
              b"dateTime" => message_info.date_time = txt.into(),
              b"batteryState" => message_info.battery_state = txt.into(),
              b"hidden" => message_info.hidden = txt.into(),
              _ => (),
            }
          },
          None => {
            match e.name().as_ref() {
              // b"counts" => 
              b"feed" => {
                section = Some("feed");
              },
              b"message" => {
                section = Some("message");
              },
                _ => (),
            }
          },
          Some(&_) => {
          },
        }
      },
      // Ok(Event::Text(e)) => {
      //   // println!("value: {:?}",e);
      // },
      Ok(Event::End(e)) => {
        // if message then save message details to vector
        match e.name().as_ref() {
          b"feed" => {
            println!("feed: {:?}",feed_info);
            section = None;
          },
          b"message" => {
            // TODO - SAVE MessageInfo to messages vector - make sure not duplicate
            println!("message: {:?}",message_info);
            section = None;
          },
          _ => {
            // error??
          },

        }

      },

      Err(e) => return Err(Box::new(e)),
      // panic!("Error at position {}: {:?}", reader.buffer_position(), e),

      _ => (), // Other events can be ignored
    }
    buf.clear();
  }

  Ok(())
}

fn generate_gpx_file(feed_id: &str) -> Result<(), Box<dyn Error>> {

  let filename = "./".to_owned() + feed_id + ".gpx";

  let gpx_file = File::create(filename)?;
  let _buf = BufWriter::new(gpx_file);

  // add the events
  // close the file

  Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {

  // get the spot feed id from the commanbd line
  let feed_id = get_feed_id();
    
  // loop for given date range

  // build the findmespot url to get the feed
  let xml_url = build_url(feed_id.as_str(), 1)?;
  
  // request the feed
  let response = reqwest::blocking::get(xml_url)?;
  let xml_content = response.text()?;

  // need feed info and vector of message info

  // parse the xml response to extract gps points
  let _result = parse_response(xml_content);

  // save the result as a gpx file
  let result= generate_gpx_file(&feed_id);

  result
}
