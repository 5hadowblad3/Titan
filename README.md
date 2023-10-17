# 1. Introduction
This directory provides the prototype of the paper: "Titan: Efficient Multi-target Directed Greybox Fuzzing"[S&P 2024]. 

# 2. Run Titan on Magma
An easier way to run Titan on the fuzzing benchmark Magma is to move this repository into "magma/fuzzers" of [magma repository](https://github.com/HexHive/magma) and then follow the [guidance](https://hexhive.epfl.ch/magma/docs/getting-started.html) to start fuzzing. For some specific modifications to ensure correct deployment, please refer to the [build_targets](https://github.com/5hadowblad3/Titan/tree/main/build_targets) repo.

# 3. Run Titan on Other Programs
For fuzzing other programs not included in Magma, you could refer to the following scripts.
- `preinstall.sh`: Support environment.
- `instrument.sh`: Generate binary for fuzzing.
- `run.sh`: Start fuzzing.
## 3.1 Environment Prerequisite
### 3.1.1 Set Environment Variable
```export TITAN=<path_of_TITAN_repository>```
### 3.1.2 Install Dependent Tools
```
apt-get update --fix-missing && \
    apt-get install -y make build-essential git wget cmake gawk 

apt-get install -y libtinfo-dev 
apt-get install -y libcap-dev zlib1g-dev

# llvm-4.0
apt-get install -y libtinfo5
apt-get install -y xz-utils
wget -q https://releases.llvm.org/4.0.0/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz
tar -xf clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz
rm clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz

cp -r clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10 /usr/llvm
cp -r /usr/llvm/bin/* /usr/bin 
cp -r /usr/llvm/lib/* /usr/lib
cp -r /usr/llvm/include/* /usr/include 
cp -r /usr/llvm/share/* /usr/share

apt-get install -y python3 python3-dev python3-pip
pip3 install --upgrade pip
pip3 install wllvm
```
## 3.2 Instrument  Binary
It is recommended to run Titan under a new folder `$TITAN/Outputs` to make sure the output files are gathered in a common folder.

```mkdir $TITAN/Outputs; cd $TITAN/Outputs```

### 3.2.1 Generate bitcode file
Generate the bitcode file for the target project by wllvm.

### 3.2.2 Static Analysis

The static analysis engine used in Titan is similar to [Beacon(S&P'22)](https://5hadowblad3.github.io/files/Oakland22-Beacon.pdf). You can have more details by accessing its [repo](https://github.com/5hadowblad3/Beacon_artifact).

```$TITAN/prototype/precondInfer <target.bc> --target-file=<cstest.txt> --join-bound=1```

**Inputs:**
- `<target.bc>` is the bitcode file for the target project.
- `<cstest.txt>` has multiple lines, which record the location of multiple targets. Each line is in the form of “fileName:lineNum” (e.g. parser.c:66 means that the target for directed fuzzing is at Line 66 of parser.c).
  
**Outputs:**
- `range_res.txt`: range analysis result.
- `transed.bc`: The slightly transformed bc for further processing.

### 3.2.3 Instrumentation

```$TITAN/prototype/Ins -output=$TITAN/Outputs/fuzz.bc -afl -res=$TITAN/Outputs -log=$TITAN/Outputs/log_Ins.txt -load=$TITAN/Outputs/range_res.txt $TITAN/Outputs/transed.bc```

### 2.2.4 Compilation

```clang $TITAN/Outputs/transed.bc -o $TITAN/Outputs/fuzz_bin -lm -lz $TITAN/prototype/afl-llvm-rt.o```

## 2.4 Fuzzing
Finally, fuzz all the things!

```$TITAN/prototype/afl-fuzz -i <seed_dir> -o $TITAN/Outputs/fuzz_out -- $TITAN/Outputs/fuzz_bin @@```

# Q&A:
## 1, Speed of the Static Analysis (Help wanted)  
Currently, Titan uses sequential static analysis for each target. Even though it is affordable as an offline one-time effort for the evaluation, it may become expensive in practice. One potential solution is to extend our static analysis as a multi-thread/process version, which can significantly reduce the analysis time. This orthogonal problem may also become a research question for efficient parallel static analysis in future work. For more implementation details and potential discussion, please feel free to drop an email or open an issue in the issue track.
