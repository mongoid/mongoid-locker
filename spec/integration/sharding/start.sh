#!/usr/bin/env bash
set -euo pipefail

mkdir -p /tmp/config /tmp/shard
mongod --configsvr --replSet config --port 27019 --bind_ip localhost --dbpath /tmp/config --logpath /tmp/config.log --fork
mongod --shardsvr --replSet shard --port 27018 --bind_ip localhost --dbpath /tmp/shard --logpath /tmp/shard.log --fork
mongosh --quiet --port 27019 --eval 'rs.initiate({_id:"config",configsvr:true,members:[{_id:0,host:"localhost:27019"}]}); while(!db.hello().isWritablePrimary) sleep(200)'
mongosh --quiet --port 27018 --eval 'rs.initiate({_id:"shard",members:[{_id:0,host:"localhost:27018"}]}); while(!db.hello().isWritablePrimary) sleep(200)'
mongos --configdb config/localhost:27019 --bind_ip_all --port 27017 --logpath /tmp/mongos.log --fork
mongosh --quiet --eval 'const result = db.adminCommand({addShard:"shard/localhost:27018"}); if (result.ok !== 1) throw new Error(JSON.stringify(result))'
exec tail -f /tmp/mongos.log
