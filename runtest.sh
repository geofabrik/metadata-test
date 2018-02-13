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
TEST9=09_apply_diff_on_pbf_to_pbf

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
mkdir -p $OUTPUT_DIR/$TEST9
rm -f $OUTPUT_DIR/$TEST1/*
rm -f $OUTPUT_DIR/$TEST2/*
rm -f $OUTPUT_DIR/$TEST3/*
rm -f $OUTPUT_DIR/$TEST4/*
rm -f $OUTPUT_DIR/$TEST5/*
rm -f $OUTPUT_DIR/$TEST6/*
rm -f $OUTPUT_DIR/$TEST7/*
rm -f $OUTPUT_DIR/$TEST8/*
rm -f $OUTPUT_DIR/$TEST9/*

# metadata variations
declare -a arr=("none" "version" "version+timestamp" "true")
declare -a progs=("osmium" "osmosis" "osmconvert")

# generate test data from hand-crafted OSM XML files
for VAR in "${arr[@]}"; do
  rm -f $INPUT_DIR/${VAR}_sparsenodes.osm.pbf $INPUT_DIR/$VAR.osm.pbf $INPUT_DIR/$VAR.osm $INPUT_DIR/testdata_newer_${VAR}.* $INPUT_DIR/testdata_newer_${VAR}_sparsenodes.osm.pbf
  $OSMIUM cat --no-progress -o $INPUT_DIR/$VAR.osm.pbf --output-format pbf,add_metadata=$VAR $INPUT_DIR/start/testdata.osm
  $OSMIUM cat --no-progress -o $INPUT_DIR/${VAR}_sparsenodes.osm.pbf --output-format pbf,add_metadata=$VAR,pbf_dense_nodes=false $INPUT_DIR/start/testdata.osm
  $OSMIUM cat --no-progress -o $INPUT_DIR/$VAR.osm --output-format osm,add_metadata=$VAR $INPUT_DIR/start/testdata.osm
  $OSMIUM cat --no-progress -o $INPUT_DIR/testdata_newer_${VAR}_sparsenodes.osm.pbf --output-format pbf,add_metadata=$VAR,pbf_dense_nodes=false $INPUT_DIR/start/testdata_newer_$VAR.osm
  $OSMIUM cat --no-progress -o $INPUT_DIR/testdata_newer_${VAR}.osm.pbf --output-format pbf,add_metadata=$VAR,pbf_dense_nodes=true $INPUT_DIR/start/testdata_newer_$VAR.osm
done

# Usage:
# run_osmium COMMAND INPUT_FILE OUTPUT_FILE SECOND_INPUT_FILE TESTCASE_NUMBER
# run_osmium COMMAND INPUT_FILE OUTPUT_FILE TESTCASE_NUMBER
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

# Usage:
# run_osmosis READ_COMMAND INPUT_FILE WRITE_COMMAND OUTPUT SECOND_COMMAND SECOND_READ_CMD SECOND_INPUT TESTCASE_NUMBER
# run_osmosis READ_COMMAND INPUT_FILE WRITE_COMMAND OUTPUT TESTCASE_NUMBER
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
    echo "$OSMOSIS -q $READ_COMMAND file=$INPUT $SECOND_READ_CMD file=$SECOND_INPUT $SECOND_COMMAND $WRITE_COMMAND file=$OUTPUT"
    $OSMOSIS -q $READ_COMMAND file=$INPUT $SECOND_READ_CMD file=$SECOND_INPUT $SECOND_COMMAND $WRITE_COMMAND file=$OUTPUT || printf "${RED}ERROR running $OSMOSIS -q $READ_COMMAND file=$INPUT $SECOND_READ_CMD file=$SECOND_INPUT $SECOND_COMMAND $WRITE_COMMAND file=$OUTPUT${NC}\n"
  else
    TESTCASE=$5
    $OSMOSIS -q $READ_COMMAND file=$INPUT $WRITE_COMMAND file=$OUTPUT || printf "${RED}ERROR running $OSMOSIS -q $READ_COMMAND file=$INPUT $WRITE_COMMAND file=$OUTPUT${NC}\n"
  fi
}

# Usage:
# run_osmium INPUT_FILE OUTPUT_FILE SECOND_INPUT_FILE FLAGS TESTCASE_NUMBER
# run_osmium INPUT_FILE OUTPUT_FILE SECOND_INPUT_FILE TESTCASE_NUMBER
# run_osmium INPUT_FILE OUTPUT_FILE TESTCASE_NUMBER
function run_osmconvert {
  INPUT=$1
  OUTPUT=$2
  if [ "$#" -eq 5 ]; then
    SECOND_INPUT=$3
    FLAGS=$4
    TESTCASE=$5
    $OSMCONVERT $INPUT $SECOND_INPUT $FLAGS -o=$OUTPUT || printf "${RED}ERROR running $OSMCONVERT $INPUT $SECOND_INPUT $FLAGS -o=$OUTPUT${NC}\n"
  elif [ "$#" -eq 4 ]; then
    SECOND_INPUT=$3
    TESTCASE=$4
    $OSMCONVERT $INPUT $SECOND_INPUT -o=$OUTPUT || printf "${RED}ERROR running $OSMCONVERT $INPUT $SECOND_INPUT -o=$OUTPUT${NC}\n"
  else
    TESTCASE=$3
    $OSMCONVERT $INPUT -o=$OUTPUT || printf "${RED}ERROR running $OSMCONVERT $INPUT -o=$OUTPUT${NC}\n"
  fi
}


############################################
# TEST CASE 1
printf "${BLUE}##########################################\n"
printf "Test case 1: Converting OSM XML to OSM XML${NC}\n"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST1/osmium_$VAR.osm 1
  run_osmosis --read-xml $INPUT_DIR/$VAR.osm --write-xml $OUTPUT_DIR/$TEST1/osmosis_$VAR.osm 1
  run_osmconvert $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST1/osmconvert_$VAR.osm 1
done

###########################################
# TEST CASE 2
printf "${BLUE}##########################################\n"
printf "Test case 2: Converting PBF to OSM XML\n${NC}"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST2/osmium_$VAR.osm 2
  run_osmosis --read-pbf $INPUT_DIR/$VAR.osm.pbf --write-xml $OUTPUT_DIR/$TEST2/osmosis_$VAR.osm 2
  run_osmconvert $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST2/osmconvert_$VAR.osm 2
  run_osmium cat $INPUT_DIR/${VAR}_sparsenodes.osm.pbf $OUTPUT_DIR/$TEST2/osmium_${VAR}_from_sparsenodes.osm 2
  run_osmosis --read-pbf $INPUT_DIR/${VAR}_sparsenodes.osm.pbf --write-xml $OUTPUT_DIR/$TEST2/osmosis_${VAR}_from_sparsenodes.osm 2
  run_osmconvert $INPUT_DIR/${VAR}_sparsenodes.osm.pbf $OUTPUT_DIR/$TEST2/osmconvert_${VAR}_from_sparsenodes.osm 2
done

###########################################
# TEST CASE 3
printf "${BLUE}##########################################\n"
printf "Test case 3: Convert OSM XML to PBF\n${NC}"

for VAR in "${arr[@]}"; do
  run_osmium cat $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST3/osmium_$VAR.osm.pbf 3
  run_osmosis --read-xml $INPUT_DIR/$VAR.osm --write-pbf $OUTPUT_DIR/$TEST3/osmosis_$VAR.osm.pbf 3
  run_osmconvert $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST3/osmconvert_$VAR.osm.pbf 3
  run_osmium cat $INPUT_DIR/${VAR}.osm $OUTPUT_DIR/$TEST3/osmium_${VAR}_sparsenodes.osm.pbf 3
  run_osmosis --read-xml $INPUT_DIR/${VAR}.osm --write-pbf "$OUTPUT_DIR/$TEST3/osmosis_${VAR}_sparsenodes.osm.pbf usedense=false" 3
done
# convert written PBFs to Osmium's debug format
for VAR in "${arr[@]}"; do
  for PROG in "${progs[@]}"; do
    if [ -f "$OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf" ] && [ -n "$OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf" ]; then
      $OSMIUM cat --no-progress -o $OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf.debug --output-format debug $OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf || echo "$OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf is broken" > $OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf.debug
    else
      echo "$PROG failed to create $OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf" > $OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf.debug
    fi
  done
  for PROG in osmium osmosis; do
    if [ -f "$OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf" ] && [ -n "$OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf" ]; then
      $OSMIUM cat --no-progress -o $OUTPUT_DIR/$TEST3/${PROG}_${VAR}_sparsenodes.osm.pbf.debug --output-format debug $OUTPUT_DIR/$TEST3/${PROG}_${VAR}_sparsenodes.osm.pbf || echo "$OUTPUT_DIR/$TEST3/${PROG}_${VAR}.osm.pbf is broken" > $OUTPUT_DIR/$TEST3/${PROG}_${VAR}_sparsenodes.osm.pbf.debug
    else
      echo "$PROG failed to create $OUTPUT_DIR/$TEST3/${PROG}_${VAR}_sparsenodes.osm.pbf" > $OUTPUT_DIR/$TEST3/${PROG}_${VAR}_sparsenodes.osm.pbf.debug
    fi
  done
done

###########################################
# TEST CASE 4
printf "${BLUE}##########################################\n"
printf "Test case 4: Apply a Diff on an XML file and output an XML file\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium apply-changes $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST4/osmium_${VARDIFF}_applied_on_$VAR.osm $INPUT_DIR/start/testdiff_$VARDIFF.osc 4
    run_osmosis --read-xml-change $INPUT_DIR/start/testdiff_$VARDIFF.osc --write-xml $OUTPUT_DIR/$TEST4/osmosis_${VARDIFF}_applied_on_$VAR.osm --apply-change --read-xml $INPUT_DIR/$VAR.osm 4
    run_osmconvert $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST4/osconvert_${VARDIFF}_applied_on_$VAR.osm $INPUT_DIR/start/testdiff_$VARDIFF.osc 4
  done
done

###########################################
# TEST CASE 5
printf "${BLUE}##########################################\n"
printf "Test case 5: Derive a Diff two XML files\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium derive-changes $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST5/osmium_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/start/testdata_newer_$VARDIFF.osm 5
    run_osmosis --read-xml $INPUT_DIR/start/testdata_newer_$VARDIFF.osm --write-xml-change $OUTPUT_DIR/$TEST5/osmosis_diff_of_${VAR}_and_${VARDIFF}.osc --derive-change --read-xml $INPUT_DIR/$VAR.osm 5
    run_osmconvert $INPUT_DIR/$VAR.osm $OUTPUT_DIR/$TEST5/osmconvert_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/start/testdata_newer_$VARDIFF.osm --diff 5
  done
done

############################################
# TEST CASE 6
printf "${BLUE}##########################################\n"
printf "Test case 6: Derive a Diff two PBF files\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium derive-changes $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST6/osmium_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/testdata_newer_$VARDIFF.osm.pbf 6
    run_osmosis --read-pbf $INPUT_DIR/testdata_newer_${VARDIFF}.osm.pbf --write-xml-change $OUTPUT_DIR/$TEST6/osmosis_diff_of_${VAR}_and_${VARDIFF}.osc --derive-change --read-pbf $INPUT_DIR/${VAR}.osm.pbf 6
    run_osmconvert $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST6/osmconvert_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/start/testdata_newer_$VARDIFF.osm.pbf --diff 6
  done
done

###########################################
# TEST CASE 7
printf "${BLUE}##########################################\n"
printf "Test case 7: Derive a Diff two PBF (no DenseNodes) files\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium derive-changes $INPUT_DIR/${VAR}_sparsenodes.osm.pbf $OUTPUT_DIR/$TEST7/osmium_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/testdata_newer_${VARDIFF}_sparsenodes.osm.pbf 7
    run_osmosis --read-pbf $INPUT_DIR/testdata_newer_${VARDIFF}_sparsenodes.osm.pbf --write-xml-change $OUTPUT_DIR/$TEST7/osmosis_diff_of_${VAR}_and_${VARDIFF}.osc --derive-change --read-pbf $INPUT_DIR/${VAR}_sparsenodes.osm.pbf 7
    run_osmconvert $INPUT_DIR/${VAR}_sparsenodes.osm.pbf $OUTPUT_DIR/$TEST7/osmconvert_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/start/testdata_newer_${VARDIFF}_sparsenodes.osm.pbf --diff 7
  done
done

###########################################
# TEST CASE 8
printf "${BLUE}##########################################\n"
printf "Test case 8: Derive a Diff of a PBF and an XML file files\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium derive-changes $INPUT_DIR/${VAR}.osm.pbf $OUTPUT_DIR/$TEST8/osmium_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/start/testdata_newer_${VARDIFF}.osm 8
    run_osmosis --read-pbf $INPUT_DIR/start/testdata_newer_${VARDIFF}.osm --write-xml-change $OUTPUT_DIR/$TEST8/osmosis_diff_of_${VAR}_and_${VARDIFF}.osc --derive-change --read-pbf $INPUT_DIR/${VAR}.osm.pbf 8
    run_osmconvert $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST8/osmconvert_diff_of_${VAR}_and_${VARDIFF}.osc $INPUT_DIR/start/testdata_newer_$VARDIFF.osm --diff 8
  done
done

###########################################
# TEST CASE 9
printf "${BLUE}##########################################\n"
printf "Test case 9: Apply a Diff on a PBF file and output an PBF file\n${NC}"

for VAR in "${arr[@]}"; do
  for VARDIFF in "${arr[@]}"; do
    run_osmium apply-changes $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST9/osmium_${VARDIFF}_applied_on_$VAR.osm.pbf $INPUT_DIR/start/testdiff_$VARDIFF.osc 9
    run_osmosis --read-xml-change $INPUT_DIR/start/testdiff_$VARDIFF.osc --write-pbf "$OUTPUT_DIR/$TEST9/osmosis_${VARDIFF}_applied_on_$VAR.osm.pbf usedense=false" --apply-change --read-pbf "$INPUT_DIR/$VAR.osm.pbf" 9
    run_osmconvert $INPUT_DIR/$VAR.osm.pbf $OUTPUT_DIR/$TEST9/osconvert_${VARDIFF}_applied_on_$VAR.osm.pbf $INPUT_DIR/start/testdiff_$VARDIFF.osc 9
  done
done
# convert written PBFs to Osmium's debug format
for VAR in "${arr[@]}"; do
  for PROG in "${progs[@]}"; do
    if [ -f "$OUTPUT_DIR/$TEST9/${PROG}_${VAR}.osm.pbf" ] && [ -n "$OUTPUT_DIR/$TEST9/${PROG}_${VAR}.osm.pbf" ]; then
      $OSMIUM cat --no-progress -o $OUTPUT_DIR/$TEST9/${PROG}_${VARDIFF}_applied_on_${VAR}.osm.pbf.debug --output-format debug $OUTPUT_DIR/$TEST9/${PROG}_${VARDIFF}_applied_on_${VAR}.osm.pbf || echo "$OUTPUT_DIR/$TEST9/${PROG}_${VARDIFF}_applied_on_${VAR}.osm.pbf is broken" > $OUTPUT_DIR/$TEST9/${PROG}_${VARDIFF}_applied_on_${VAR}.osm.pbf.debug
    else
      echo "$PROG failed to create $OUTPUT_DIR/$TEST9/${PROG}_${VARDIFF}_applied_on_${VAR}.osm.pbf" > $OUTPUT_DIR/$TEST9/${PROG}_${VARDIFF}_applied_on_${VAR}.osm.pbf.debug
    fi
  done
done
