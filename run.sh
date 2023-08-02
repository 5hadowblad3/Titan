#!/bin/bash
set -x

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env SHARED: path to directory shared with host (to store results)
# - env PROGRAM: name of program to run (should be found in $OUT)
# - env ARGS: extra arguments to pass to the program
# - env FUZZARGS: extra arguments to pass to the fuzzer
##

mkdir -p "$SHARED/findings"

export AFL_SKIP_CPUFREQ=1
export AFL_NO_AFFINITY=1

# cp -r $OUT/output-$PROGRAM $SHARED

if [[ $TARGET = *openssl* || $TARGET = *lua* || $TARGET = *libpng* ]]; then
    echo "set timeout -t 1000+"
	FUZZ_TIMEOUT="-t 1000+"
fi

"$FUZZER/repo/prototype/afl-fuzz" -m 100M $FUZZ_TIMEOUT -i "$TARGET/corpus/$PROGRAM" -o "$SHARED/findings" -s "$OUT/output-$PROGRAM/bug_conf_cluster" -k "$OUT/output-$PROGRAM/bug_over_cluster" \
    $FUZZARGS -- "$OUT/$PROGRAM" $ARGS 2>&1
