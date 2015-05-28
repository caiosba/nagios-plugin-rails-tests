#!/bin/bash
# Check if tests of a Rails application are passing
# Usage: check_rails_tests.sh <repository URL (mandatory)> <command that configures the application>

md5=$(echo $1 | md5sum | sed 's/ .*//g')
basedir=/tmp/nagios-check-rails-tests
dir="$basedir/$md5"

if [ ! -d "$dir" ]
then
  mkdir -p $basedir 2>/dev/null
  git clone $1 $dir 2>/dev/null >/dev/null
fi

cd $dir
git pull 2>&1 >/dev/null
source $2 >/dev/null 2>/dev/null
bundle install 2>/dev/null >/dev/null
bundle exec rake db:migrate 2>/dev/null >/dev/null
output=$(bundle exec rake test 2>/dev/null | tail -n 1)
cd - 2>/dev/null >/dev/null

tests=$(echo $output | sed 's/.*\( \|^\)\([0-9]\+\) tests.*/\2/g')
failures=$(echo $output | sed 's/.*\( \|^\)\([0-9]\+\) failures.*/\2/g')
errors=$(echo $output | sed 's/.*\( \|^\)\([0-9]\+\) errors.*/\2/g')

if [ $tests -eq 0 ]
then
  echo "WARNING: No tests found: $output"
  exit 1
fi

if [ $errors -eq 0 ] && [ $failures -eq 0 ]
then
  echo "OK: All tests are passing: $output"
  exit 0
fi

if [ $errors -ne 0 ] || [ $failures -ne 0 ]
then
  echo "CRITICAL: Some tests are failing: $output"
  exit 2
fi

echo "UNKNOWN: Unexpected output: $output"
exit 3
