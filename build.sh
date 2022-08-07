set e+x

LOCAL_NAME=cypress/browsers:node16.14.2-slim-chrome103-ff102
echo "Building $LOCAL_NAME"
docker build -t $LOCAL_NAME .