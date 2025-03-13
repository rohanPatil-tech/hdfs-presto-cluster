#!/bin/bash

#!/bin/bash

function test_hdfs_q1() {
    docker-compose -f cs598p1-compose.yaml exec main hdfs dfsadmin -report >&2
}

function test_hdfs_q2() {
    docker compose -f cs598p1-compose.yaml cp resources/fox.txt main:/test_fox.txt
    docker-compose -f cs598p1-compose.yaml exec main bash -x -c '\
        hdfs dfs -mkdir -p /test; \
        hdfs dfs -put -f /test_fox.txt /test/fox.txt; \
        hdfs dfs -cat /test/fox.txt'
}

function test_hdfs_q3() {
    docker-compose -f cs598p1-compose.yaml exec main bash -x -c '\
        hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://main:9000 -op create -threads 100 -files 10000; \
        hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://main:9000 -op open -threads 100 -files 10000; \
        hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://main:9000 -op delete -threads 100 -files 10000; \
        hadoop org.apache.hadoop.hdfs.server.namenode.NNThroughputBenchmark -fs hdfs://main:9000 -op rename -threads 100 -files 10000'
}

function test_hdfs_q4() {
    docker compose -f cs598p1-compose.yaml cp resources/hadoop-terasort-3.3.6.jar \
    main:/hadoop-terasort-3.3.6.jar
docker-compose -f cs598p1-compose.yaml exec main bash -x -c '\
    hdfs dfs -rm -r -f tera-in tera-out tera-val; \
    hadoop jar /hadoop-terasort-3.3.6.jar teragen 1000000 tera-in; \
    hadoop jar /hadoop-terasort-3.3.6.jar terasort tera-in tera-out; \
    hadoop jar /hadoop-terasort-3.3.6.jar teravalidate tera-out tera-val; \
    hdfs dfs -cat tera-val/*;'
}

function test_presto_q1() {
    docker-compose -f cs598p1-compose.yaml exec -T main bash -c "presto" <<EOF
        SELECT * FROM system.runtime.nodes;
        EXIT;
EOF
}

function test_presto_q2 () {
    docker-compose -f cs598p1-compose.yaml exec -T main bash -c 'ps -ef | grep HiveMetaStore'
}

function test_presto_q3_1 () {
    docker-compose -f cs598p1-compose.yaml exec -T main bash -c "presto" <<EOF
        show schemas from hive;
EOF
}

function test_presto_q3_2 () {
    docker-compose -f cs598p1-compose.yaml exec -T main bash -c "presto" <<EOF
        show tables from hive.information_schema;
EOF
}

function test_presto_q4() {
    docker compose -f cs598p1-compose.yaml cp resources/house-price.parquet main:/house-price.parquet
    docker-compose -f cs598p1-compose.yaml exec main bash -x -c '\
        hdfs dfs -mkdir -p /test/house-price; \
        hdfs dfs -put -f /house-price.parquet /test/house-price/house-price.parquet;'
    docker-compose -f cs598p1-compose.yaml exec -T main bash -c "presto" <<EOF
        use hive.default;
        CREATE TABLE if not exists house_data(
            price BIGINT,
            area BIGINT,
            bedrooms BIGINT,
            bathrooms BIGINT,
            stories BIGINT,
            mainroad VARCHAR,
            guestroom VARCHAR,
            basement VARCHAR,
            hotwaterheating VARCHAR,
            airconditioning VARCHAR,
            parking BIGINT,
            prefarea VARCHAR,
            furnishingstatus VARCHAR
        )
        WITH (
            format = 'PARQUET',
            external_location = 'hdfs://main:9000/test/house-price'
        );
        select * from house_data limit 5;
EOF
}

function test_presto_q5() {
    docker compose -f cs598p1-compose.yaml cp resources/presto_q5.sql main:/presto_q5.sql
    docker-compose -f cs598p1-compose.yaml exec main bash -x -c '\
    cat /presto_q5.sql | presto'
}


GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p out

total_score=0;

echo -n "Testing HDFS Q1 ..."
test_hdfs_q1 > out/test_hdfs_q1.out 2>&1
if grep -q "Live datanodes (3)" out/test_hdfs_q1.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing HDFS Q2 ..."
test_hdfs_q2 > out/test_hdfs_q2.out 2>&1
if grep -E -q '^The quick brown fox jumps over the lazy dog[[:space:]]*$' out/test_hdfs_q2.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing HDFS Q3 ..."
test_hdfs_q3 > out/test_hdfs_q3.out 2>&1
if [ "$(grep -E '# operations: 10000[[:space:]]*$' out/test_hdfs_q3.out | wc -l)" -eq 4 ]; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=5 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing HDFS Q4 ..."
test_hdfs_q4 > out/test_hdfs_q4.out 2>&1
if [ "$(grep -E 'Job ([[:alnum:]]|_)+ completed successfully[[:space:]]*$' out/test_hdfs_q4.out | wc -l)" -eq 3 ] && grep -q "7a27e2d0d55de" out/test_hdfs_q4.out; then
    echo -e " ${GREEN}PASS${NC}";
    (( total_score+=5 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing presto Q1 ..."
test_presto_q1 > out/test_presto_q1.out 2>&1
# First, verify that the output includes all three node names.
if grep -q "main" out/test_presto_q1.out && \
   grep -q "worker1" out/test_presto_q1.out && \
   grep -q "worker2" out/test_presto_q1.out; then
   # Next, verify that:
   # - main has "true" in the coordinator column and "active" in the state column
   # - worker1 has "false" in the coordinator column and "active" in the state column
   # - worker2 has "false" in the coordinator column and "active" in the state column
   if grep -qE "^ *main *\|.*\|.*\| *true *\| *active *$" out/test_presto_q1.out && \
      grep -qE "^ *worker1 *\|.*\|.*\| *false *\| *active *$" out/test_presto_q1.out && \
      grep -qE "^ *worker2 *\|.*\|.*\| *false *\| *active *$" out/test_presto_q1.out; then
      echo -e " ${GREEN}PASS${NC}"
      (( total_score+=20 ));
   else
      echo -e " ${RED}FAIL${NC}"
   fi
else
   echo -e " ${RED}FAIL${NC}"
fi


echo -n "Testing Presto Q2..."
test_presto_q2 > out/test_presto_q2.out 2>&1

# Check if "org.apache.hadoop.hive.metastore.HiveMetaStore" appears in the output
if grep -q "org.apache.hadoop.hive.metastore.HiveMetaStore" out/test_presto_q2.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=20 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing Presto Q3_1..."
test_presto_q3_1 > out/test_presto_q3_1.out 2>&1

# Check if "org.apache.hadoop.hive.metastore.HiveMetaStore" appears in the output
if grep -q "information_schema" out/test_presto_q3_1.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=5 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing Presto Q3_2..."
test_presto_q3_2 > out/test_presto_q3_2.out 2>&1

# Check if "org.apache.hadoop.hive.metastore.HiveMetaStore" appears in the output
if grep -q "tables" out/test_presto_q3_2.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=5 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo -n "Testing Presto Q4..."
test_presto_q4 > out/test_presto_q4.out 2>&1

# Check if "org.apache.hadoop.hive.metastore.HiveMetaStore" appears in the output
if grep -q "(5 rows)" out/test_presto_q4.out; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi



echo -n "Testing Presto Q5..."
test_presto_q5 > out/test_presto_q5.raw 2>&1

declare -A expected_prices=(
    [1]=2712500
    [2]=3632022
    [3]=4954598
    [4]=5729757
    [5]=5819800
    [6]=4791500
)

sed -r "s/\x1B\[[0-9;]*[mK]//g" out/test_presto_q5.raw > out/test_presto_q5.clean
grep -E "^[[:space:]]+#bedrooms[[:space:]]+\|[[:space:]]+average price|^[[:space:]]+[0-9]+[[:space:]]+\|[[:space:]]+[0-9]+(\.[0-9]+)?" out/test_presto_q5.clean > out/test_presto_q5.out

# Flag to track if all tests pass
all_pass=true

# Read the output file and validate each row
while read -r line; do
    # Skip header and footer lines
    if [[ $line == "#bedrooms"* || $line == "(6 rows)"* || $line == "----"* ]]; then
        continue
    fi

    # Parse the number of bedrooms and average price (integer part)
    bedrooms=$(echo $line | awk '{print $1}')
    avg_price=$(echo $line | awk '{print $3}' | cut -d'.' -f1)

    # Check if the value matches the expected result
    if [[ ${expected_prices[$bedrooms]} -ne $avg_price ]]; then
        echo -e " ${RED}FAIL${NC} - Mismatch for #bedrooms=$bedrooms (Expected: ${expected_prices[$bedrooms]}, Found: $avg_price)"
        all_pass=false
    fi
done < out/test_presto_q5.out


# Final result
if $all_pass; then
    echo -e " ${GREEN}PASS${NC}"
    (( total_score+=10 ));
else
    echo -e " ${RED}FAIL${NC}"
fi

echo "-----------------------------------";
echo "Total Points/Full Points: ${total_score}/100";
