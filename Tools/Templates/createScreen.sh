#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: ./createScreen.sh MyScreen [subFolder]"
    exit 1
fi 

SCREEN_NAME=$1
SCREEN_VAR_NAME=`echo $SCREEN_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`

MODULE_DIR="../../Riot/Modules"

OUTPUT_DIR="$MODULE_DIR"
if [ $# -eq 2 ]; 
then
    OUTPUT_DIR="$OUTPUT_DIR/$2"
    if [ ! -e $OUTPUT_DIR ]; then
        echo "Create folder ${OUTPUT_DIR}"
        mkdir $OUTPUT_DIR
    fi 
fi
OUTPUT_DIR="$OUTPUT_DIR/$1"


if [ -e $OUTPUT_DIR ]; then
    echo "Error: Folder ${OUTPUT_DIR} already exists"
    exit 1
fi 

echo "Create folder ${OUTPUT_DIR}"

cp -R buildable/ScreenTemplate $OUTPUT_DIR

cd $OUTPUT_DIR
for file in *
do
    echo "Building ${file/TemplateScreen/$SCREEN_NAME}..."
    perl -p -i -e "s/TemplateScreen/"$SCREEN_NAME"/g" $file
    perl -p -i -e "s/templateScreen/"$SCREEN_VAR_NAME"/g" $file
    mv ${file} ${file/TemplateScreen/$SCREEN_NAME}
done