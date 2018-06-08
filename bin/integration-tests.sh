#!/usr/bin/env bash

# define some colors to use for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# project name has to be "docker" likely because Travis uses an older version
# of docker-compose ignoring -p.
PROJECT=docker

# kill and remove any running containers
cleanup () {
  docker-compose -p $PROJECT kill
  docker-compose -p $PROJECT rm -f --all
}
# catch unexpected failures, do cleanup and output an error message
trap 'cleanup ; printf "${RED}Tests Failed For Unexpected Reasons${NC}\n"'\
  HUP INT QUIT PIPE TERM
cd docker
# build and run the composed services
docker-compose -p $PROJECT build && docker-compose -p $PROJECT up -d
if [ $? -ne 0 ] ; then
  printf "${RED}Docker Compose Failed${NC}\n"
  exit -1
fi
echo "Waiting for tests to finish"
# wait for the test service to complete and grab the exit code
TEST_EXIT_CODE=`docker wait ${PROJECT}_tests_1`
echo "Listing docker logs"
# output the logs for the test (for clarity)
docker logs ${PROJECT}_tests_1
# inspect the output of the test and display respective message
if [ -z ${TEST_EXIT_CODE+x} ] || [ "$TEST_EXIT_CODE" -ne 0 ] ; then
  printf "${RED}Tests Failed${NC} - Exit Code: $TEST_EXIT_CODE\n"
else
  printf "${GREEN}Tests Passed${NC}\n"
fi
# call the cleanup fuction
cleanup
# exit the script with the same code as the test service code
exit $TEST_EXIT_CODE
