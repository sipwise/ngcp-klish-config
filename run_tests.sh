#!/bin/bash

mkdir -p reports
rm -rf reports/*

function run()
{
	echo "testing $1 -> reports/$2.tap"
			cat<<EOF|lua5.1 - > reports/$2.tap
require "tests/$2"
---- Control test output:
lu = LuaUnit
lu:setOutputType('TAP')
lu:setVerbosity(1)
lu:run()
EOF
}

if [[ -z "$@" ]]; then
	TESTS=$(find tests -name '*.lua' -exec basename {} .lua \;|xargs)
else
	TESTS=$@
fi

for i in $TESTS; do
	f="tests/$i.lua"
	if [ ! -f $f ]; then
		echo "No $f found"
	else
		run $f $i
	fi
done
exit 0
#EOF