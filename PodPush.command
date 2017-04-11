#!/bin/bash

cd $(dirname $0)

diff=`git diff`


if [ ${#diff} != 0 ];
then
    echo "还有东西没有提交"
    exit 1
fi

echo "--------tag list--------"
git tag -l
echo "--------tag list--------"

echo "根据上面的tag输入新tag"
read thisTag

# 获取podspec文件名
podSpecName=`ls|grep ".podspec$"|sed "s/\.podspec//g"`
echo $podSpecName

# 修改版本号
sed -i "" "s/s.version *= *[\"\'][^\"]*[\"\']/s.version=\"$thisTag\"/g" $podSpecName.podspec


pod lib lint $podSpecName.podspec --allow-warnings


# 验证失败退出
if [ $? != 0 ];then
    exit 1
fi




git commit $podSpecName.podspec -m "update podspec"
git push
git tag -m "update podspec" $thisTag
git push --tags

# pod repo push PrivatePods --sources=$sources
pod trunk push $podSpecName.podspec
