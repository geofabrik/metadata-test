# OSM Metadata Test Suite

This is a test suite which can be used to check how certain OpenStreetMap software works with
OpenStreetMap data which has all, some or no metadata fields.

## Software covered

* [Osmium-Tool](https://github.com/osmcode/osmium-tool) which uses [Libosmium](https://github.com/osmcode/libosmium)
* [Osmosis](https://wiki.openstreetmap.org/wiki/Osmosis)
* [Osmconvert](https://wiki.openstreetmap.org/wiki/Osmconvert)

See [table.ods](https://github.com/geofabrik/metadata-test/raw/master/table.ods) for a table of the results.

## Run the tests

The tests are not fully automated. They only produce a large number of OSM files you can inspect.
Run

```sh
./runtest.sh run
```

in the top level directory of this repository to execut the tests. Run `./runtest.sh clean` to
remove all produced files.

The produced files are located in subdirectories of the directory `output/`.

## License

See [COPYING.txt](COPYING.txt)
