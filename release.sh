#!/bin/bash

set -ex

VERSION=$(cat version)

sed -i "" -e "s/  SDK_VERSION = '[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*'/  SDK_VERSION = '$VERSION'/g" lib/berbix.rb
sed -i "" -e "s/  s.version = '[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*'/  s.version = '$VERSION'/g" berbix.gemspec

git add berbix.gemspec lib/berbix.rb version
git commit -m "Updating Berbix Ruby SDK version to $VERSION"
git tag -a $VERSION -m "Version $VERSION"
git push --follow-tags

gem build berbix.gemspec
gem push berbix-$VERSION.gem
