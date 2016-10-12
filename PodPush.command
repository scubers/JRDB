#!/bin/bash

cd $(dirname $0)

diff=`git diff`


if [ ${#diff} != 0 ] 
then
    echo "还有东西没有提交"
    exit
fi

echo "--------tag list--------"
git tag -l
echo "--------tag list--------"

echo "请输入tag"
read thisTag
echo $thisTag

# read podSpecName
podSpecName="JRDB"

echo $podSpecName

sed -i "" "s/s.version *= *[\"\'][^\"]*[\"\']/s.version=\"$thisTag\"/g" $podSpecName.podspec

git commit $podSpecName.podspec -m "update podspec"
git push
git tag -m "update podspec" $thisTag
git push --tags

pod lib lint

pod trunk push $podSpecName.podspec