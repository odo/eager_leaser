# EagerLeaser

This is an experiment to test how leases can be equally distributed given a changing set of workers.

## Concept

It makes the following assumptions:

* leases are stored centrally in a DB
* workers are started and stopped
* each worker tries to aquire one lease every tick
* each worker renews its leases every tick
* when an worker is stoppend it stops renewing its leases
* when leases are not renewed, they expire and become available again
* when a new worker is started, all others are asked to drain their leases
* draining a lease means to wait a random time and then return it

## Lease States

```
       free
       ^  +
       |  |
return |  |lease
       |  |
       +  v
       taken <---+
       ^  +  |   | renew
       |  |  +---+
lease  |  |
       |  |
       +  v
       expired
```

## Simulation

The algorithm can be tested interactively in IEx. `EagerLeaser.list` can be used to inspect the state of leases:

```elixir
{1529533414, :taken,
 %{
   #PID<0.118.0> => [6, 7, 9, 11, 12, 14, 17, 20, 23, 25, 30, 32, 35, 39, 44,
    46, 61, 67, 68, 69, 75, 76, 78, 80, 85, 86, 92],
   #PID<0.122.0> => [3, 4, 8, 10, 21, 24, 28, 31, 43, 48, 50, 52, 54, 55, 60,
    65, 66, 70, 81, 82, 87, 88, 91, 95, 96, 97, 100]
 }}
{1529533414, :expired,
 %{
   #PID<0.120.0> => [1, 5, 13, 15, 18, 26, 29, 33, 34, 37, 49, 51, 59, 79, 84,
    90, 98]
 }}
{1529533414, :free,
 [99, 94, 93, 89, 83, 77, 74, 73, 72, 71, 64, 63, 62, 58, 57, 56, 53, 47, 45,
  42, 41, 40, 38, 36, 27, 22, 19, 16, 2]}
```
In this example we have two active workers (0.118.0 amd 0.122.0) who own some leases. Also we have a set of expired leases that used to belong to 0.120.0 and some free leases.

Using `EagerLeaser.list`, `EagerLeaser.start_worker` and `EagerLeaser.stop_worker` we can play with the system and see how it behaves.
