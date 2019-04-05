#!/bin/bash

if [ ! $# -eq 2 ] && [ ! $# -eq 3 ] ; then
    echo "Usage: ./createRootCoordinator.sh Folder MyRootCoordinatorName [DefaultScreenName]"
    exit 1
fi 


OUTPUT_DIR="../../Riot/Modules"/$1
COORDINATOR_NAME=$2
COORDINATOR_VAR_NAME=`echo $COORDINATOR_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`
SCREEN_NAME=$3
SCREEN_VAR_NAME=`echo $SCREEN_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`
    
MODULE_DIR="../../Riot/Modules"

echo "Create folder ${OUTPUT_DIR}"

mkdir -p $OUTPUT_DIR
cp -R buildable/FlowCoordinatorTemplate/ $OUTPUT_DIR/

cd $OUTPUT_DIR
for file in FlowTemplate*
do
    if [ -f "$file" ]; then
        echo "Building ${file/FlowTemplate/$COORDINATOR_NAME}..."
        perl -p -i -e "s/FlowTemplate/"$COORDINATOR_NAME"/g" $file
        perl -p -i -e "s/flowTemplate/"$COORDINATOR_VAR_NAME"/g" $file
    
        if [ -n "$SCREEN_NAME" ]; then
            perl -p -i -e "s/TemplateScreen/"$SCREEN_NAME"/g" $file
            perl -p -i -e "s/templateScreen/"$SCREEN_VAR_NAME"/g" $file
        fi
        
        echo "// $ createRootCoordinator.sh $@" | cat - ${file} > /tmp/$$ && mv /tmp/$$ ${file}
        echo '// File created from FlowTemplate' | cat - ${file} > /tmp/$$ && mv /tmp/$$ ${file}
    
        mv ${file} ${file/FlowTemplate/$COORDINATOR_NAME}
    fi
done