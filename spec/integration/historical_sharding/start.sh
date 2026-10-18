#!/usr/bin/env bash
set -euo pipefail

trap 'status=$?; if [ "$status" != 0 ]; then cat /tmp/historical-*.log; fi' EXIT

mkdir -p /tmp/historical-config
mongod --configsvr --port 27019 --bind_ip 127.0.0.1 --dbpath /tmp/historical-config --logpath /tmp/historical-config.log --fork
for port in 27018 27020; do
  mkdir -p "/tmp/historical-shard-$port"
  mongod --shardsvr --replSet "historical$port" --port "$port" --bind_ip 127.0.0.1 \
    --oplogSize 16 --dbpath "/tmp/historical-shard-$port" --logpath "/tmp/historical-shard-$port.log" --fork
  mongo --quiet --port "$port" --eval \
    "var result = rs.initiate({_id:'historical$port',members:[{_id:0,host:'localhost:$port'}]}); if (result.ok !== 1) throw new Error(JSON.stringify(result));"
  for attempt in $(seq 1 60); do
    if mongo --quiet --port "$port" --eval 'quit(db.isMaster().ismaster ? 0 : 1)'; then
      break
    fi
    if [ "$attempt" = 60 ]; then
      exit 1
    fi
    sleep 1
  done
done
mongos --configdb localhost:27019 --bind_ip 127.0.0.1 --port 27017 --logpath /tmp/historical-mongos.log --fork
mongo --quiet --eval '
  function check(result) { if (result.ok !== 1) throw new Error(JSON.stringify(result)); }
  check(db.adminCommand({addShard:"historical27018/localhost:27018", name:"first"}));
  check(db.adminCommand({addShard:"historical27020/localhost:27020", name:"second"}));
  check(db.adminCommand({enableSharding:"locker_2013"}));
  if (db.getSiblingDB("config").databases.findOne({_id:"locker_2013"}).primary !== "first")
    check(db.adminCommand({movePrimary:"locker_2013", to:"first"}));
  if (db.getSiblingDB("config").databases.findOne({_id:"locker_2013"}).primary !== "first")
    throw new Error("Expected first shard to be the database primary");
  sh.stopBalancer();
  ["ranged", "hashed", "tenant"].forEach(function(name) {
    var key = name === "tenant" ? {tenant:1} : {_id:name === "hashed" ? "hashed" : 1};
    var collection = db.getSiblingDB("locker_2013").getCollection(name);
    collection.ensureIndex(key);
    if (db.getLastError() !== null) throw new Error(db.getLastError());
    check(db.adminCommand({shardCollection:"locker_2013." + name, key:key, numInitialChunks:1}));
    var boundary = name === "tenant" ? {tenant:"m"} :
      {_id:name === "hashed" ? NumberLong(0) : ObjectId("800000000000000000000000")};
    check(db.adminCommand({split:"locker_2013." + name, middle:boundary}));
    if (name === "hashed") {
      check(db.adminCommand({moveChunk:"locker_2013." + name,
        bounds:[boundary, {_id:MaxKey}], to:"second", _waitForDelete:true}));
    } else {
      check(db.adminCommand({moveChunk:"locker_2013." + name, find:boundary, to:"second", _waitForDelete:true}));
    }
  });
'
ruby /reproduction/reproduce.rb
