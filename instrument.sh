#!/bin/bash
set -e
##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env MAGMA: path to Magma support files
# - env PROGRAM: name of program to run (should be found in $OUT)
# - env OUT: path to directory where artifacts are stored
# - env CFLAGS and CXXFLAGS must be set to link against Magma instrumentation
##

export LIBS="$LIBS -l:driver.o -lstdc++"
 
"$MAGMA/build.sh"

# replace the build scripts for specific targets
(
	if [[ $TARGET = *sqlite3* ]]; then
		cp $FUZZER/build_targets/sqlite3.sh $TARGET/build.sh
	fi
)

(
	echo -e "## Build by wllvm"
	export PATH="/usr/local/bin:$PATH"
	export CC="wllvm" # "wllvm"
	export CXX="wllvm++"
	export LLVM_COMPILER=clang

	"$TARGET/build.sh"
)

(
	echo "## Get Target"

	if [[ $TARGET = *sqlite3* ]]; then
		pushd $TARGET/work
	else
		pushd $TARGET/repo
	fi

	echo "targets"
	grep -nr MAGMA_LOG | cut -f1,2 -d':' | grep -v ".orig:"  | grep -v "Binary file" > $OUT/cstest.txt

	cat $OUT/cstest.txt
)

(
	echo "## Build by Titan"
    cd "$OUT"
    source "$TARGET/configrc"
    for p in "${PROGRAMS[@]}"; do (
		folder=$OUT/output-$p
		if [ ! -d $folder ]; then
			mkdir $folder
		fi
		cd $folder
		mv ../$p .
		extract-bc "./$p"

		echo "[+] precondInfer"
		$FUZZER/repo/prototype/precondInfer $p.bc --target-file=../cstest.txt --join-bound=1 > log_precond.txt 2>&1
		
		echo "[+] Ins"
		$FUZZER/repo/prototype/Ins -output=$folder/fuzz.bc -afl -res=$folder -log=log_Ins.txt -load=$folder/range_res.txt $folder/transed.bc

		echo "[+] Compile"
		export CC=clang; export CXX=clang++;
		input_bc=$folder/fuzz.bc
		output_bin=$OUT/$p
		afl_llvm_rt=$FUZZER/repo/prototype/afl-llvm-rt.o
		export BUILD_BC_LIBS="$LIBS -lrt" 
		pushd "$TARGET/repo"
		if [[ $TARGET = *libpng* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS .libs/libpng16.a -lz -lm
		elif [[ $TARGET = *libsndfile* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS -lmp3lame -lmpg123 -lFLAC -lvorbis -lvorbisenc -lopus -logg -lm
		elif [[ $TARGET = *libtiff* ]]; then
			WORK="$TARGET/work"
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS $WORK/lib/libtiffxx.a $WORK/lib/libtiff.a -lm -lz -ljpeg -Wl,-Bstatic -llzma -Wl,-Bdynamic
		elif [[ $TARGET = *libxml2* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS .libs/libxml2.a -lz -llzma -lm
		elif [[ $TARGET = *lua* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS $TARGET/repo/liblua.a -DLUA_USE_LINUX -DLUA_USE_READLINE -lreadline -lm -ldl  # -L/$OUT 
		elif [[ $TARGET = *openssl* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS -lpthread ./libcrypto.a ./libssl.a
		elif [[ $TARGET = *php* ]]; then
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS -lstdc++ -lpthread -lboost_fiber -lboost_context
		elif [[ $TARGET = *poppler* ]]; then
			WORK="$TARGET/work"
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS -I"$WORK/poppler/cpp" -I"$TARGET/repo/cpp" \
			"$WORK/poppler/cpp/libpoppler-cpp.a" "$WORK/poppler/libpoppler.a" "$WORK/lib/libfreetype.a" -lz -llzma -ljpeg -lz -lopenjp2 -lpng -ltiff -llcms2 -lm -lpthread -pthread
		elif [[ $TARGET = *sqlite3* ]]; then
                        WORK="$TARGET/work"
			$CXX $CXXFLAGS -std=c++11 -I. $input_bc -o $output_bin $afl_llvm_rt $LDFLAGS $BUILD_BC_LIBS $WORK/.libs/libsqlite3.a -lpthread -pthread -ldl -lm -lz
		else 
			echo "Could not support this target $TARGET"
		fi
		popd
	)
	done
)
