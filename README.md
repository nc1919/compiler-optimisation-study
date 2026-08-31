# Performance Programming: compiler optimisation study

A small single-threaded C molecular-dynamics/N-body workload used to compare compiler optimisation modes. The dominant kernel computes pairwise interactions for 4,096 bodies; the repository includes the input fixture, a result comparator, and a repeatable Slurm sweep.

## Build and run

Requirements: a C11 compiler, `make`, and a POSIX-like environment.

```bash
make -C MD/C MODE=release
(cd MD/C && ./MD 20)
```

Available modes are `debug`, `release`, `fast`, and `fast_lto`. The `fast` modes relax floating-point semantics, so compare their generated outputs with the release baseline.

On a Slurm system, first review the site-specific partition, QoS, and module directives, then run:

```bash
sbatch MD/bench_compiler.slurm
```

The script records repeated timings below `MD/results/`, which is intentionally ignored.

## Recorded result

The removed analysis notebook contained the following 20-step arithmetic means:

| Case | Mean time (s) | Speedup vs release |
|---|---:|---:|
| `release` | 36.6824 | 1.00× |
| `release_arch` | 36.6876 | 1.00× |
| `fast_arch` | 5.3030 | 6.92× |

These figures lack a preserved compiler version and hardware record, so treat them as historical observations rather than reproducible portfolio claims. Re-run the checked-in sweep and report compiler, flags, processor, replicate count, dispersion, and comparator output.

This repository represents the compiler-configuration phase of the work. The separate `Peformance-Programming` repository contains later hand-optimised kernels.

## Publication notes

This began as coursework. Confirm module policy and any contributor permissions before changing visibility. No project-wide licence has been selected; review does not grant reuse rights.
