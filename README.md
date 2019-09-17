# Submission specs

input representation: symbolic, monophonic

subtasks: 1

threads: see Parallelization

expected memory footprint:

expected runtime:

requirements: sbcl, quicklisp, sqlite3

# Usage

Move the training data (monophonic midi files) into a new directory called `training-data`.
Move the primes (monophonic midi files) into a new directory called `primes`.
Create a directory `results`, where the results will be stored.
Results are CSV files.

Alternatively, run 

```bash
make all
```

To use the medium training set, and sample 100 primes at random from this training set.

To generate results, run

```
chmod +x run.sh
./run.sh
```

# Parallelization

As many instances of this code as desired can be run in parallel on disjoint subsets of primes.
