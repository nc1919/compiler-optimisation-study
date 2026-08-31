#!/bin/bash
#SBATCH --job-name=md_compiler_sweep
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --time=01:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --exclusive
#SBATCH --output=log_md_compiler_%j.txt
#SBATCH --error=log_md_compiler_%j.err

set -euo pipefail

module load PrgEnv-gnu

ROOT="${SLURM_SUBMIT_DIR:-$PWD}"
WORKDIR="${ROOT}/MD/C"
RESULTS="${ROOT}/MD/results"

NSTEP="${NSTEP:-20}"         # 5 blocks x NSTEP timesteps
REPEATS="${REPEATS:-3}"
ARCH_FLAGS_DEFAULT="${ARCH_FLAGS_DEFAULT:--march=native}"
EXTRA_FLAGS_DEFAULT="${EXTRA_FLAGS_DEFAULT:--D_DEFAULT_SOURCE}"

mkdir -p "${RESULTS}"

echo "Working dir: ${WORKDIR}"
echo "Results dir: ${RESULTS}"
echo "NSTEP=${NSTEP} REPEATS=${REPEATS} ARCH_FLAGS_DEFAULT=${ARCH_FLAGS_DEFAULT}"

# Build diff tool
make -C "${ROOT}/MD/Test" clean
make -C "${ROOT}/MD/Test"

run_case () {
  local tag="$1"
  local mode="$2"
  local arch_flags="$3"

  echo "== Case: ${tag} =="
  make -C "${WORKDIR}" clean
  make -C "${WORKDIR}" MODE="${mode}" ARCH_FLAGS="${arch_flags}" EXTRA_FLAGS="${EXTRA_FLAGS_DEFAULT}"

  for rep in $(seq 1 "${REPEATS}"); do
    local rep_dir="${RESULTS}/${tag}/rep${rep}"
    mkdir -p "${rep_dir}"
    pushd "${WORKDIR}" >/dev/null
    ./MD "${NSTEP}" > "${rep_dir}/run.log"
    mv output.dat* "${rep_dir}/"
    popd >/dev/null
  done
}

baseline_tag="release"
run_case "${baseline_tag}" "release" ""

baseline_file="${RESULTS}/${baseline_tag}/rep1/output.dat$(printf "%03d" $((NSTEP*5)))"

run_case "release_arch" "release" "${ARCH_FLAGS_DEFAULT}"
run_case "fast" "fast" ""
run_case "fast_arch" "fast" "${ARCH_FLAGS_DEFAULT}"
run_case "fast_lto_arch" "fast_lto" "${ARCH_FLAGS_DEFAULT}"

echo "== Correctness check vs baseline (${baseline_file}) =="
for tag in release_arch fast fast_arch fast_lto_arch; do
  current="${RESULTS}/${tag}/rep1/output.dat$(printf "%03d" $((NSTEP*5)))"
  echo "-- ${tag}"
  "${ROOT}/MD/Test/diff-output" "${baseline_file}" "${current}" || true
done

echo "== Timing summary (first replicate per case) =="
for tag in release release_arch fast fast_arch fast_lto_arch; do
  echo "-- ${tag}"
  awk '/timesteps took/ {print}' "${RESULTS}/${tag}/rep1/run.log"
done
