#!/bin/bash

if [ ! $# -eq 4 ]; then
    echo "Usage: ./createSwiftUITwoScreen.sh Folder MyRootCoordinatorName MyFirstScreenName MyDetailScreenName"
    exit 1
fi

MODULE_DIR="../../RiotSwiftUI/Modules"
OUTPUT_DIR=$MODULE_DIR/$1

COORDINATOR_NAME=$2
COORDINATOR_VAR_NAME=`echo $COORDINATOR_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`
FIRST_SCREEN_NAME=$3
FIRST_SCREEN_VAR_NAME=`echo $FIRST_SCREEN_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`
DETAIL_SCREEN_NAME=$4
DETAIL_SCREEN_VAR_NAME=`echo $DETAIL_SCREEN_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`



TEMPLATE_DIR=$MODULE_DIR/Template/TemplateAdvancedRoomsExample/
if [ -e $OUTPUT_DIR ]; then
    echo "Error: Folder ${OUTPUT_DIR} already exists"
    exit 1
fi

echo "Create folder ${OUTPUT_DIR}"

mkdir -p $OUTPUT_DIR
cp -R $TEMPLATE_DIR $OUTPUT_DIR/

cd $OUTPUT_DIR

mv "TemplateRoomList" $FIRST_SCREEN_NAME
mv "TemplateRoomChat" $DETAIL_SCREEN_NAME

for file in $(find * -type f -print)
do
  if [[ $file == "Coordinator"* ]]; then
    echo "Building ${file/TemplateRooms/$COORDINATOR_NAME}..."
    perl -p -i -e "s/TemplateRooms/"$COORDINATOR_NAME"/g" $file
    perl -p -i -e "s/templateRooms/"$COORDINATOR_VAR_NAME"/g" $file

    mv ${file} ${file/TemplateRooms/$COORDINATOR_NAME}
  elif [[ $file == $FIRST_SCREEN_NAME* ]]; then
    echo "Building ${file/TemplateRoomList/$FIRST_SCREEN_NAME}..."
    perl -p -i -e "s/TemplateRoomList/"$FIRST_SCREEN_NAME"/g" $file
    perl -p -i -e "s/templateRoomList/"$FIRST_SCREEN_VAR_NAME"/g" $file
    mv ${file} ${file/TemplateRoomList/$FIRST_SCREEN_NAME}
  elif [[ $file == $DETAIL_SCREEN_NAME* ]]; then
    echo "Building ${file/TemplateRoomChat/$DETAIL_SCREEN_NAME}..."
    perl -p -i -e "s/TemplateRoomChat/"$DETAIL_SCREEN_NAME"/g" $file
    perl -p -i -e "s/templateRoomChat/"$DETAIL_SCREEN_VAR_NAME"/g" $file
    mv ${file} ${file/TemplateRoomChat/$DETAIL_SCREEN_NAME}
  fi
done
