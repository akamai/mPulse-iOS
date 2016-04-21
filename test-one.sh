#
# Tests a single test method or class
#

if [ $# -eq 0 ]; then
  # Nothing to do
  echo "Usage:    ./test-one.sh [class] [method]"
  echo "Examples: ./test-one.sh MPURLSessionTests"
  echo "          ./test-one.sh MPURLSessionTests testThreadedDataTaskWithRequestSuccess"
  exit
elif [ $# -eq 1 ]; then
  TEST=$1
elif [ $# -eq 2 ]; then
  TEST=$1/$2
fi

xctool \
  -workspace Boomerang.xcworkspace \
  -scheme BoomerangTests \
  -sdk iphonesimulator \
  test \
  -only BoomerangTests:$TEST \
  -parallelize \
  -logicTestBucketSize 1 \
  -reporter junit:junit.xml \
  -reporter pretty
