# September 2013 sharding reproduction

This standalone attempt investigates [issue #19](https://github.com/mongoid/mongoid-locker/issues/19) using dependencies available when it was reported on September 11, 2013, rather than the current checkout's implementation.

| Component | Version | Provenance |
| --- | --- | --- |
| Ruby | 2.0.0p247 | Exact Ruby version shown in the report |
| MongoDB | 2.4.6 | [Release tag](https://github.com/mongodb/mongo/tree/r2.4.6), August 2013 |
| mongoid-locker | 0.2.1 | [Published November 28, 2012](https://rubygems.org/gems/mongoid-locker/versions/0.2.1), latest published release before the report |
| Mongoid | 3.1.0 | [Published February 13, 2013](https://rubygems.org/gems/mongoid/versions/3.1.0), compatible with the published locker's dependency constraint |
| Moped | 1.4.5 | Historical Mongoid driver |

All gem versions, including transitive dependencies, are pinned in the Dockerfile and checked against `gems.sha256`. Ruby and MongoDB are the historical x86-64 binaries/runtime; Ubuntu 20.04 is a build host, not a reconstruction of the reporter's operating system. OpenSSL 1.0.1e is compiled solely so this Ruby's gem installer can load; downloads use the host image's modern curl, and gem installation is local.

## Run

From the repository root:

```sh
docker build --platform linux/amd64 -t locker-2013 spec/integration/historical_sharding
docker run --rm --platform linux/amd64 --network none locker-2013
```

These obsolete dependencies are for an isolated experiment only, not supported application use. The runtime has no network access outside its container, no published ports, and no host mounts. The build requires network access. Apple Silicon requires Docker's x86-64 emulation. A dedicated GitHub Actions workflow runs the same commands when these files change and can also be dispatched manually after merging.

## What it checks

The bootstrap creates one configuration server, two single-member replica-set shards, and a `mongos` router. It stops the balancer, splits the empty collections, and moves one chunk of each sharded collection to the second shard before inserting data. Hashed chunks are split and moved explicitly rather than using the multi-chunk initialization path: with `numInitialChunks: 2` on this server, an initial experiment stored 16 documents physically but exposed only 8 through the router. The reproduction asserts router visibility as well as physical placement so such a fixture failure cannot be reported as successful locking.

Four collections each contain 16 fresh documents:

* Unsharded control.
* Ranged `_id` shard key.
* Hashed `_id` shard key.
* `tenant` shard key, matching the report's other-key control.

Each sharded collection must have documents physically stored on both shards. Each document is fetched through `mongos`, checked for initially nil lock fields, locked with the published gem's default options, updated, and reloaded. One document per collection uses the report's `Item.first` path; the others use explicit ID lookups. Assertions check persisted acquisition timestamps, the saved value, and cleared lock fields after release. Each expected ID is attempted explicitly, and the final persisted update count must match the successful acquisitions.

## Result

The original `Mongoid::Locker::LockError` **did not reproduce** on this stack. The October 18, 2026 run produced:

```text
Ruby 2.0.0p247
MongoDB 2.4.6
moped 1.4.5
mongoid 3.1.0
mongoid-locker 0.2.1
{"collection":"unsharded","shard_counts":[16,0]}
{"collection":"unsharded","acquired":16,"attempted":16}
{"collection":"ranged","shard_counts":[8,8]}
{"collection":"ranged","acquired":16,"attempted":16}
{"collection":"hashed","shard_counts":[8,8]}
{"collection":"hashed","acquired":16,"attempted":16}
{"collection":"tenant","shard_counts":[8,8]}
{"collection":"tenant","acquired":16,"attempted":16}
No reproduction: all 64 fresh documents acquired and released their locks.
```

This is not proof that the production report was wrong or that a particular later release fixed it. The report does not specify its MongoDB, Mongoid, Moped, or locker versions, shard topology, or complete model configuration. This experiment does not cover concurrent chunk migration, multiple routers, secondary reads, contention, or multi-member replica sets. It complements the modern sharding suite; it neither changes runtime behavior nor tests the current gem.
