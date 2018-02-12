#! /usr/bin/env bash

set -eu

OSMIUM=~/git/osmium-tool/build/osmium
OSMOSIS=osmosis
OSMCONVERT=osmconvert

OUTPUT_DIR=output
INPUT_DIR=input

TEST1=01_convert_xml_to_xml
TEST2=02_convert_pbf_to_xml
TEST3=03_convert_xml_to_pbf
TEST4=04_apply_diff_on_xml_to_xml
TEST5=05_derive_diff_from_xml
TEST6=06_derive_diff_from_pbf

# create output subdirectories
mkdir -p $OUTPUT_DIR/$TEST1
mkdir -p $OUTPUT_DIR/$TEST2
mkdir -p $OUTPUT_DIR/$TEST3
mkdir -p $OUTPUT_DIR/$TEST4
mkdir -p $OUTPUT_DIR/$TEST5
mkdir -p $OUTPUT_DIR/$TEST6

# metadata variations
declare -a arr("none" "version" "version+timestamp" "true")

# generate test data from hand-crafted OSM XML files
for VAR in "${arr[@]}"; do
  $OSMIUM cat -o $INPUT_DIR/$VAR.osm.pbf --output-format pbf,add_metadata=$VAR $INPUT_DIR/testdata.osm
  $OSMIUM cat -o $INPUT_DIR/$VAR.osmf --output-format osm,add_metadata=$VAR $INPUT_DIR/testdata.osm
done

# define function
# Positional parameters:
# 1. command
# 2. input file
# 3. output file
function run_osmium {
  COMMAND=$1
  INPUT=$2
  OUTPUT=$3
  $OSMIUM $COMMAND -o $OUTPUT $INPUT || echo "ERROR running $OSMIUM $COMMAND -o $OUTPUT $INPUT"
}

# Positional parameters:
# 1. read command (e.g. --read-xml)
# 2. input file
# 3. write command
# 4. output file
# 5. second command (e.g. --derive-changes)
function run_osmosis {
  READ_COMMAND=$1
  INPUT=$2
  WRITE_COMMAND=$3
  OUTPUT=$4
  if [ "$#" -gt 4 ]; then
    SECOND_COMMAND=$5
    $OSMOSIS $READ_COMMNAD file=$INPUT $SECOND_COMMAND $WRITE_COMMAND file=$OUTPUT || echo "ERROR running Osmosis"
  else
    $OSMOSIS $READ_COMMNAD file=$INPUT $WRITE_COMMAND file=$OUTPUT || echo "ERROR running Osmosis"
  fi
}

###########################################
# TEST CASE 1
echo "Test case 1: Converting OSM XML to OSM XML"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST1/$VAR.osm
  run_osmosis --read-xml $INPUT_DIR/$VAR.osm --write-xml $OUTPUT_DIR/$TEST1/$VAR.osm
done

###########################################
# TEST CASE 2
echo "Test case 2: Converting PBF to OSM XML"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST1/$VAR.osm
  run_osmosis --read-xml $INPUT_DIR/$VAR.osm.pbf --write-xml $OUTPUT_DIR/$TEST1/$VAR.osm
done

###########################################
# TEST CASE 3
echo "Test case 3: Convert OSM XML to PBF"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST1/$VAR.osm.pbf
  run_osmosis --read-xml $INPUT_DIR/$VAR.osm --write-xml $OUTPUT_DIR/$TEST1/$VAR.osm.pbf
done

