# findmespot-gpx

## overview

a collection of scripts to process gps data from the (findme)Spot tracker.  Users can either get the data from an XML feed or from the [maps website](https://maps.findmespot.com).

- The XML data is a feed of events but only had history from the point the feed was created and only for up to 6 days.  So the data needs to be pulled regularly.  Note, don't worry about overlap as the code will remove any duplicates between various pulls of the xml feed
- The [maps website](https://maps.findmespot.com) makes an AJAX request to the backend which returns a JSON response with the data.  You can set the range of dates to include the events you want. Once the map has been displayed, you will use the developer mode of the browser to get the JSON response from the network tab.  Look for `GetLatestPositionsForAssetsReq`.  Take the JSON response and save it to a file which the scripts will process.

While there is some rust code to pull down the XML feed, the rest of the code is in ruby.  There is a small amount of javascript to convert gpx to geojson but the ruby code does this as well.  The ruby scripts will add the data from Spot into a SQLite database.  This is done to collate and de-dup data from multiple input files.  The gpx files are generated from the data in the SQLite database.

## Extraction Scripts

read the events data for a Spot tracker from the XML feed and save to a file

```bash
# will get 1st 50 events
findmespot-gpx feed-id
```

## Generate GPX file

to process any XML or JSON files, use one of the following two scripts.  They read the data from the files and store them in a SQLite database.  The database will be called `feed_data.db`.  You can see the database structure if you look into `database.rb`

```bash
cd ruby
bundle install
ruby process_xml.rb filename
ruby process_json.rb filename
```

Once the data is in the SQLite database, you can then generate the gpx files.

```bash
ruby generate_gpx.rb output_filename
```

## Conversion Scripts

```bash
cd js
node index.js filename
```

## Misc

if you want a summary of what's in a given gpx file

```bash
ruby /ruby/analyze_gpx.rb gpx_filename
```

## Future

- right now the code just gets the 1st 50 events of the XML feed.  It should really get all the events.
- once it has some events, the next time it runs, its smart enough to know which events are new and only get those
