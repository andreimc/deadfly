# DeadFly

Is a simple proxy that allows you to basically shut down any fly machine in x seconds of inactivity

The first request is required to start the init process.

This is designed to be used in conjunction with fly.io, hence the name of this :).

Since Firecracker VMS can run multiple processes you can put this in front of any service and it will shut down based on requests.

## Roadmap

* Add enhanced support for multiple apps, so you can run a DB + an API on the same machine or multiple little services

* Multi-path hosting so you can host something under `/app` or `/db`