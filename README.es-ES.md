# 1. Introducción
Este directorio proporciona el prototipo del artículo: "Titan: Efficient Multi-target Directed Greybox Fuzzing"(S&P 2024). 

# 2. Ejecutar Titan en Magma
Una forma más sencilla de ejecutar Titan en el benchmark de fuzzing Magma es mover este repositorio a "magma/fuzzers" del [repositorio de magma](https://github.com/HexHive/magma) y luego seguir la [guía](https://hexhive.epfl.ch/magma/docs/getting-started.html) para iniciar el fuzzing. **La única adaptación que debe realizar es extraer las ubicaciones de los objetivos (targets) de esos errores para que Titan pueda inferirlos.** Para algunas modificaciones específicas para asegurar un despliegue correcto, consulte el repo [build_targets](https://github.com/5hadowblad3/Titan/tree/main/build_targets).

# 3. Ejecutar Titan en otros programas
Para realizar fuzzing en otros programas no incluidos en Magma, puede referirse a los siguientes scripts.
- `preinstall.sh`: Entorno de soporte.
- `instrument.sh`: Genera el binario para fuzzing.
- `run.sh`: Inicia el fuzzing.
## 3.1 Requisitos del Entorno
### 3.1.1 Configurar Variable de Entorno
```export TITAN=<path_of_TITAN_repository>```
### 3.1.2 Instalar Herramientas Dependientes
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
## 3.2 Instrumentar Binario
Se recomienda ejecutar Titan bajo una nueva carpeta `$TITAN/Outputs` para asegurar que los archivos de salida se reúnan en una carpeta común.

```mkdir $TITAN/Outputs; cd $TITAN/Outputs```

### 3.2.1 Generar archivo bitcode
Genere el archivo bitcode para el proyecto objetivo mediante wllvm.

### 3.2.2 Análisis Estático

El motor de análisis estático utilizado en Titan es similar a [Beacon(S&P'22)](https://5hadowblad3.github.io/files/Oakland22-Beacon.pdf). Puede obtener más detalles accediendo a su [repo](https://github.com/5hadowblad3/Beacon_artifact).

```$TITAN/prototype/precondInfer <target.bc> --target-file=<cstest.txt> --join-bound=1```

**Entradas:**
- `<target.bc>` es el archivo bitcode del proyecto objetivo.
- `<cstest.txt>` contiene múltiples líneas que registran la ubicación de múltiples objetivos. Cada línea tiene la forma “fileName:lineNum” (por ejemplo, parser.c:66 significa que el objetivo para el fuzzing dirigido está en la línea 66 de parser.c).
  
**Salidas:**
- `range_res.txt`: resultado del análisis de rangos.
- `transed.bc`: el archivo bc ligeramente transformado para procesamiento posterior. 
- `bug_conf_cluster`: información de clúster para correlaciones de conflicto.
- `bug_over_cluster`: información de clúster para correlaciones de solapamiento/independencia.

Tenga en cuenta que la información de independencia está incluida en los dos archivos anteriores.

### 3.2.3 Instrumentación

```$TITAN/prototype/Ins -output=$TITAN/Outputs/fuzz.bc -afl -res=$TITAN/Outputs -log=$TITAN/Outputs/log_Ins.txt -load=$TITAN/Outputs/range_res.txt $TITAN/Outputs/transed.bc```

### 2.2.4 Compilación

```clang $TITAN/Outputs/fuzz.bc -o $TITAN/Outputs/fuzz_bin -lm -lz $TITAN/prototype/afl-llvm-rt.o```

## 2.4 Fuzzing
Finalmente, ¡haga fuzzing de todo!

```$TITAN/prototype/afl-fuzz -i <seed_dir> -o $TITAN/Outputs/fuzz_out -s "$TITAN/Outputs/bug_conf_cluster" -k "$TITAN/Outputs/bug_over_cluster" -- $TITAN/Outputs/fuzz_bin <other_parameters> @@```

# Q&A:
## 1. Velocidad del Análisis Estático (Se solicita ayuda)  
Actualmente, Titan utiliza análisis estático secuencial para cada objetivo. Aunque es aceptable como un esfuerzo único offline para la evaluación del artículo, puede resultar costoso en la práctica. Una solución potencial es extender nuestro análisis estático a una versión multihilo/multiproceso, lo que podría reducir significativamente el tiempo de análisis. Este problema ortogonal también podría convertirse en una pregunta de investigación para el análisis estático paralelo eficiente en trabajos futuros. Para más detalles sobre la implementación y posibles discusiones, no dude en enviar un correo electrónico o abrir un issue en el rastreador de issues.
