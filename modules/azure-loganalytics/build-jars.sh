#!/usr/bin/env bash

function print_jars {
    A_JAR=$(realpath spark-monitoring/src/target/spark-listeners_*.jar)
    B_JAR=$(realpath spark-monitoring/src/target/spark-listeners-loganalytics_*.jar)
    echo "{\"spark-listeners.jar\": \"$A_JAR\", \"spark-listeners-loganalytics.jar\": \"$B_JAR\"}"
    exit 0
}

if [[ `ls spark-monitoring/src/target/* 2> /dev/null | wc -l` -ne 0 ]]; then
    print_jars
fi

PROFILE="${1:-scala-2.12_spark-3.0.1}"

echo "" > build.log
rm -fr spark-monitoring >> build.log 2>&1
git clone https://github.com/mspnp/spark-monitoring >> build.log 2>&1
mvn -f spark-monitoring/src/pom.xml -P$PROFILE -DskipTests package >> build.log 2>&1

print_jars