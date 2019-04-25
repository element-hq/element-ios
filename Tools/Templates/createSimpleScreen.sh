#!/bin/bash

if [ ! $# -eq 2 ]; then
    echo "Usage: ./createSimpleScreen.sh Folder MyScreenName"
    exit 1
fi 

OUTPUT_DIR="../../Riot/Modules"/$1
SCREEN_NAME=$2
SCREEN_VAR_NAME=`echo $SCREEN_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`

MODULE_DIR="../../Riot/Modules"

if [ -e $OUTPUT_DIR ]; then
    echo "Error: Folder ${OUTPUT_DIR} already exists"
    exit 1
fi 

echo "Create folder ${OUTPUT_DIR}"

mkdir -p $OUTPUT_DIR
cp -R buildable/SimpleScreenTemplate/ $OUTPUT_DIR/

cd $OUTPUT_DIR
for file in *
do
    echo "Building ${file/SimpleScreenTemplate/$SCREEN_NAME}..."
    perl -p -i -e "s/SimpleScreenTemplate/"$SCREEN_NAME"/g" $file
    perl -p -i -e "s/simpleScreenTemplate/"$SCREEN_VAR_NAME"/g" $file
    
    if [[ ! $file == *.storyboard ]];
    then
        echo "// $ createSimpleScreen.sh $@" | cat - ${file} > /tmp/$$ && mv /tmp/$$ ${file}
        echo '// File created from simpleScreenTemplate' | cat - ${file} > /tmp/$$ && mv /tmp/$$ ${file}
    fi
    
    mv ${file} ${file/SimpleScreenTemplate/$SCREEN_NAME}
done