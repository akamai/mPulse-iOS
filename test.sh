# Run BoomerangTests
xctool \
  -workspace Boomerang.xcworkspace \
  -scheme BoomerangTests \
  -sdk iphonesimulator \
  test \
  -parallelize \
  -logicTestBucketSize 1 \
  -reporter junit:junit.xml \
  -reporter pretty

if [ $? -ne 0 ]; then
  echo "BoomerangTests failure, not running BoomerangTestsWithPods"
  exit 1
fi

# Run BoomerangTestsWithPods
xctool \
  -workspace Boomerang.xcworkspace \
  -scheme BoomerangTestsWithPods \
  -sdk iphonesimulator \
  test \
  -parallelize \
  -logicTestBucketSize 1 \
  -reporter junit:junit-pods.xml \
  -reporter pretty