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
TEST6=06_derive_diff_from_pbf_densnodes
TEST7=07_derive_diff_from_pbf_no_densenodes
TEST8=08_derive_diff_pbf_and_xml

RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clean() {
  rm -rf $OUTPUT_DIR
  rm $INPUT_DIR/*.*
  exit 0
}

if [ "$#" -lt 1 ]; then
  echo "Missing argument, should be either \"run\" or \"clean\". Exiting."
  exit 1
fi
if [ "$1" = "clean" ]; then
  clean
fi
if [ "$1" != "run" ]; then
  echo "Missing argument, should be either \"run\" or \"clean\". Exiting."
  exit 1
fi

# create output subdirectories
mkdir -p $OUTPUT_DIR/$TEST1
mkdir -p $OUTPUT_DIR/$TEST2
mkdir -p $OUTPUT_DIR/$TEST3
mkdir -p $OUTPUT_DIR/$TEST4
mkdir -p $OUTPUT_DIR/$TEST5
mkdir -p $OUTPUT_DIR/$TEST6
mkdir -p $OUTPUT_DIR/$TEST7
mkdir -p $OUTPUT_DIR/$TEST8
rm -f $OUTPUT_DIR/$TEST1/*
rm -f $OUTPUT_DIR/$TEST2/*
rm -f $OUTPUT_DIR/$TEST3/*
rm -f $OUTPUT_DIR/$TEST4/*
rm -f $OUTPUT_DIR/$TEST5/*
rm -f $OUTPUT_DIR/$TEST6/*
rm -f $OUTPUT_DIR/$TEST7/*
rm -f $OUTPUT_DIR/$TEST8/*

# metadata variations
declare -a arr=("none" "version" "version+timestamp" "true")

# generate test data from hand-crafted OSM XML files
for VAR in "${arr[@]}"; do
  rm -f $INPUT_DIR/${VAR}_sparsenodes.osm.pbf $INPUT_DIR/$VAR.osm.pbf $INPUT_DIR/$VAR.osm $INPUT_DIR/testdata_newer_${VAR}.* $INPUT_DIR/testdata_newer_${VAR}_sparsenodes.osm.pbf
  $OSMIUM cat -o $INPUT_DIR/$VAR.osm.pbf --output-format pbf,add_metadata=$VAR $INPUT_DIR/start/testdata.osm
  $OSMIUM cat -o $INPUT_DIR/${VAR}_sparsenodes.osm.pbf --output-format pbf,add_metadata=$VAR,pbf_dense_nodes=false $INPUT_DIR/start/testdata.osm
  $OSMIUM cat -o $INPUT_DIR/$VAR.osm --output-format osm,add_metadata=$VAR $INPUT_DIR/start/testdata.osm
  $OSMIUM cat -o $INPUT_DIR/testdata_newer_${VAR}_sparsenodes.osm.pbf --output-format pbf,add_metadata=$VAR,pbf_dense_nodes=false $INPUT_DIR/start/testdata_newer_$VAR.osm
  $OSMIUM cat -o $INPUT_DIR/testdata_newer_${VAR}.osm.pbf --output-format pbf,add_metadata=$VAR,pbf_dense_nodes=true $INPUT_DIR/start/testdata_newer_$VAR.osm
done

# define function
# Positional parameters:
# 1. command
# 2. input file
# 3. output file
# 4. test case number
function run_osmium {
  COMMAND=$1
  INPUT=$2
  OUTPUT=$3
  if [ "$#" -gt 4 ]; then
    INPUT2=$4
    TESTCASE=$5
    $OSMIUM $COMMAND --no-progress -o $OUTPUT $INPUT $INPUT2 || printf "${RED}ERROR running $OSMIUM $COMMAND -o $OUTPUT $INPUT $INPUT2${NC}\n"
  else
    TESTCASE=$4
    $OSMIUM $COMMAND --no-progress -o $OUTPUT $INPUT || printf "${RED}ERROR running $OSMIUM $COMMAND -o $OUTPUT $INPUT${NC}\n"
  fi
}

# Positional parameters:
# 1. read command (e.g. --read-xml)
# 2. input file
# 3. write command
# 4. output file
# 5. test case number
# 6. second command (e.g. --derive-changes)
# 7. second read command (e.g. --read-xml-change)
# 8. second input file
function run_osmosis {
  READ_COMMAND=$1
  INPUT=$2
  WRITE_COMMAND=$3
  OUTPUT=$4
  if [ "$#" -gt 5 ]; then
    SECOND_COMMAND=$5
    SECOND_READ_CMD=$6
    SECOND_INPUT=$7
    TESTCASE=$8
    $OSMOSIS -q $READ_COMMAND file=$INPUT $SECOND_READ_CMD $SECOND_INPUT $SECOND_COMMAND $WRITE_COMMAND file=$OUTPUT || printf "${RED}ERROR running $OSMOSIS -q $READ_COMMAND file=$INPUT $SECOND_COMMAND $SECOND_READ_CMD file=$SECOND_INPUT $WRITE_COMMAND file=$OUTPUT${NC}\n"
  else
    TESTCASE=$5
    $OSMOSIS -q $READ_COMMAND file=$INPUT $WRITE_COMMAND file=$OUTPUT || printf "${RED}ERROR running $OSMOSIS -q $READ_COMMAND file=$INPUT $WRITE_COMMAND file=$OUTPUT${NC}\n"
  fi
}

###########################################
# TEST CASE 1
printf "${BLUE}##########################################\n"
printf "Test case 1: Converting OSM XML to OSM XML${NC}\n"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST1/osmium_$VAR.osm 1
  run_osmosis --read-xml $INPUT_DIR/$VAR.osm --write-xml $OUTPUT_DIR/$TEST1/osmosis_$VAR.osm 1
done

###########################################
# TEST CASE 2
printf "${BLUE}##########################################\n"
printf "Test case 2: Converting PBF to OSM XML\n${NC}"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST2/osmium_$VAR.osm 2
  run_osmosis --read-pbf $INPUT_DIR/$VAR.osm.pbf --write-xml $OUTPUT_DIR/$TEST2/osmosis_$VAR.osm 2
  run_osmium cat $INPUT_DIR/${VAR}_sparsenodes.osm.pbf $OUTPUT_DIR/$TEST2/osmium_${VAR}_from_sparsenodes.osm 2
  run_osmosis --read-pbf $INPUT_DIR/${VAR}_sparsenodes.osm.pbf --write-xml $OUTPUT_DIR/$TEST2/osmosis_${VAR}_from_sparsenodes.osm 2
done

###########################################
# TEST CASE 3
printf "${BLUE}##########################################\n"
printf "Test case 3: Convert OSM XML to PBF\n${NC}"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST3/osmium_$VAR.osm.pbf 3
  run_osmosis --read-xml $INPUT_DIR/$VAR.osm --write-pbf $OUTPUT_DIR/$TEST3/osmosis_$VAR.osm.pbf 3
  run_osmium cat $INPUT_DIR/${VAR}.osm $OUTPUT_DIR/$TEST3/osmium_${VAR}_sparsenodes.osm.pbf 3
  run_osmosis --read-xml $INPUT_DIR/${VAR}.osm --write-pbf $OUTPUT_DIR/$TEST3/osmosis_${VAR}_sparsenodes.osm.pbf 3
done
#TODO convert written PBFs to Osmiums debug format

###########################################
# TEST CASE 4
printf "${BLUE}##########################################\n"
printf "Test case 4: Apply a Diff on an XML file and output an XML file\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium apply-changes $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST4/osmium_${VARDIFF}_applied_on_$VAR.osm $INPUT_DIR/start/testdiff_$VARDIFF.osc 4
    run_osmosis --read-xml $INPUT_DIR/$VAR.osm --write-xml $OUTPUT_DIR/$TEST4/osmosis_${VARDIFF}_applied_on_$VAR.osm --apply-change --read-xml-change $INPUT_DIR/start/testdiff_$VARDIFF.osc 4
  done
done

###########################################
# TEST CASE 5
printf "${BLUE}##########################################\n"
printf "Test case 5: Derive a Diff two XML files\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium derive-changes $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST5/osmium_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/start/testdata_newer_$VARDIFF.osm 5
    run_osmosis --read-xml $INPUT_DIR/$VAR.osm --write-xml-change $OUTPUT_DIR/$TEST5/osmosis_diff_of_${VAR}_and_${VARDIFF}.osc --derive-change --read-xml $INPUT_DIR/start/testdata_newer_$VARDIFF.osm 5
  done
done

###########################################
# TEST CASE 6
printf "${BLUE}##########################################\n"
printf "Test case 6: Derive a Diff two PBF files\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium derive-changes $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST6/osmium_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/testdata_newer_$VARDIFF.osm.pbf 6
    run_osmosis --read-pbf $INPUT_DIR/$VAR.osm.pbf --write-xml-change $OUTPUT_DIR/$TEST6/osmosis_diff_of_${VAR}_and_${VARDIFF}.osc --derive-change --read-pbf $INPUT_DIR/testdata_newer_$VARDIFF.osm.pbf 6
  done
done

###########################################
# TEST CASE 7
printf "${BLUE}##########################################\n"
printf "Test case 7: Derive a Diff two PBF (no DenseNodes) files\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium derive-changes $INPUT_DIR/${VAR}_sparsenodes.osm.pbf $OUTPUT_DIR/$TEST7/osmium_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/testdata_newer_${VARDIFF}_sparsenodes.osm.pbf 7
    run_osmosis --read-pbf $INPUT_DIR/${VAR}_sparsenodes.osm.pbf --write-xml-change $OUTPUT_DIR/$TEST7/osmosis_diff_of_${VAR}_and_${VARDIFF}.osc --derive-change --read-pbf $INPUT_DIR/testdata_newer_${VARDIFF}_sparsenodes.osm.pbf 7
  done
done

###########################################
# TEST CASE 8
printf "${BLUE}##########################################\n"
printf "Test case 8: Derive a Diff of a PBF and an XML file files\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium derive-changes $INPUT_DIR/${VAR}.osm.pbf $OUTPUT_DIR/$TEST8/osmium_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/start/testdata_newer_${VARDIFF}.osm 8
    run_osmosis --read-pbf $INPUT_DIR/${VAR}.osm.pbf --write-xml-change $OUTPUT_DIR/$TEST8/osmosis_diff_of_${VAR}_and_${VARDIFF}.osc --derive-change --read-pbf $INPUT_DIR/start/testdata_newer_${VARDIFF}.osm 8
  done
done
