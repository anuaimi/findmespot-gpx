#!/usr/bin/env node
const fs = require('fs');
const tj = require('@tmcw/togeojson');
const DOMParser = require('@xmldom/xmldom').DOMParser;

function process_file(filename, index) {
  
  const parts = filename.split(".");
  const base = parts[0];
  const ext = parts[1];

  if (ext === 'gpx') {

    // read the file 
    const gpxFilePath = "./data/" + filename;
    fs.readFile(gpxFilePath, 'utf8', (err, gpxData) => {
      if (err) {
        console.error('Error reading the GPX file:', err);
        return;
      } 

      const gpxDOM = new DOMParser().parseFromString(gpxData, 'text/xml');
      const geoJSON = tj.gpx(gpxDOM);

      const outputFilePath = "./data/" + base + ".geojson";
      fs.writeFile(outputFilePath, JSON.stringify(geoJSON, null, 2), 'utf8', (err) => {
        if (err) {
            console.error('Error writing GeoJSON file:', err);
            return;
        }
        console.log('GeoJSON has been saved to:', outputFilePath);
      });
    });

  }
  else if (ext === 'kml')  {
    // read the file 
    const gpxFilePath = "./data/" + filename;
    fs.readFile(gpxFilePath, 'utf8', (err, gpxData) => {
      if (err) {
        console.error('Error reading the GPX file:', err);
        return;
      } 

      const kmlDOM = new DOMParser().parseFromString(gpxData, 'text/xml');
      const geoJSON = tj.kml(kmlDOM);

      const outputFilePath = "./data/" + base + ".geojson";
      fs.writeFile(outputFilePath, JSON.stringify(geoJSON, null, 2), 'utf8', (err) => {
        if (err) {
            console.error('Error writing GeoJSON file:', err);
            return;
        }
        console.log('GeoJSON has been saved to:', outputFilePath);
      });
    });
    
  }
  else {
    // could be kml or geojson
    // process.stdout.write(filename+"\n");
  }
  
}

// get a list of files to convert
var files = fs.readdirSync('data');

// for each file call togeojson
files.forEach(process_file);


// const tj = require("@tmcw/togeojson");


