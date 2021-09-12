#!/bin/bash

if [ ! $# -eq 2 ]; then
    echo "Usage: ./createSwiftUITwoScreen.sh Folder MyScreenName"
    exit 1
fi

MODULE_DIR="../../RiotSwiftUI/Modules"
OUTPUT_DIR=$MODULE_DIR/$1
SCREEN_NAME=$2
SCREEN_VAR_NAME=`echo $SCREEN_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`
TEMPLATE_DIR=$MODULE_DIR/Template/TemplateAdvancedRoomsExample/TemplateRoomList/
if [ -e $OUTPUT_DIR ]; then
    echo "Error: Folder ${OUTPUT_DIR} already exists"
    exit 1
fi

echo "Create folder ${OUTPUT_DIR}"

mkdir -p $OUTPUT_DIR
cp -R $TEMPLATE_DIR $OUTPUT_DIR/

cd $OUTPUT_DIR
for file in $(find * -type f -print)
do
  echo "Building ${file/TemplateRoomList/$SCREEN_NAME}..."
  perl -p -i -e "s/TemplateRoomList/"$SCREEN_NAME"/g" $file
  perl -p -i -e "s/templateRoomList/"$SCREEN_VAR_NAME"/g" $file

  # echo "// $ createScreen.sh $@" | cat - ${file} > /tmp/$$ && mv /tmp/$$ ${file}
  # echo '// File created from TemplateAdvancedRoomsExample' | cat - ${file} > /tmp/$$ && mv /tmp/$$ ${file}

  mv ${file} ${file/TemplateRoomList/$SCREEN_NAME}
done
