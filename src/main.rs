use std::env;
use std::error::Error;
use std::process::exit;
use reqwest;
use quick_xml::Reader;
use quick_xml::events::Event;

fn main() -> Result<(), Box<dyn Error>> {

  let args: Vec<String> = env::args().collect();
  if args.len() != 2 {
    println!("Usage: quick");
    exit(-1);
  }

  let feed_id = &args[1];
  println!("{}", feed_id);
    
  let base_url = "https://api.findmespot.com/spot-main-web/consumer/rest-api/2.0/public/feed/";
  let xml_url = base_url.to_string() + &feed_id + "/message.xml";

  let response = reqwest::blocking::get(xml_url)?;
  let xml_content = response.text()?;

  let mut reader = Reader::from_str(&xml_content);
  reader.trim_text(true);

  let mut buf = Vec::new();
  loop {
    match reader.read_event_into(&mut buf) {
      Ok(Event::Eof) => break,
      Ok(Event::Start(_)) => {
          // Handle the start of an XML element
          // Example: println!("Start of element: {:?}", reader.read_text(b"", &mut Vec::new())?);
      },
      Ok(Event::Text(e)) => {
        println!("{:?}",e);
          // Handle the text content of an XML element
          // Example: println!("Text content: {:?}", e.unescape_and_decode(&reader)?);
      },
      Ok(Event::End(_)) => {
          // Handle the end of an XML element
      },
      Err(e) => return Err(Box::new(e)),
      _ => (), // Other events can be ignored
    }
    buf.clear();
  }
  

  Ok(())
}
