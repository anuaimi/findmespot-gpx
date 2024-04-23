# convert_fpx

code to convert gpx files to geojson so I can create maps from them

## setup

```bash
npm install 
```

## converting files

will convert all the gpx files in the data directory

```bash
node index.js
```

if you just want to do a single file

```bash
npx @tmcw/togeojson-cli file.kml > output.geojson
```
