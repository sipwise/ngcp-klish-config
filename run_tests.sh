#!/bin/bash

mkdir -p reports
rm -rf reports/*

function run()
{
  local tmpfile
  tmpfile=$(mktemp)

  echo "testing $1 -> reports/$2.tap"
  cat > "${tmpfile}" << EOF
require "tests/$2"
---- Control test output:
local lu = require('luaunit')
lu:setVerbosity(1)
local runner = lu.LuaUnit.new()
runner:setOutputType('TAP')
runner:runSuite()
EOF
  lua5.1 - < "${tmpfile}" > "reports/$2.tap"
  rm -f "${tmpfile}"
}

if [[ -z "$@" ]]; then
	TESTS="$(find tests -name '*.lua' -exec basename {} .lua \;)"
else
	TESTS=$*
fi

for i in $TESTS; do
	f="tests/$i.lua"
	if [ ! -f "$f" ]; then
		echo "No $f found"
	else
		run "$f" "$i"
	fi
done
exit 0
