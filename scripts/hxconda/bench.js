/*
    Speed benchmark of node-limited searches: the candidate (bin/hxconda.js) against the last accepted build
    (baseline/hxconda.js) and the reference Anaconda engine. Builds with the same behaviour visit the same nodes, so wall
    time compares the implementations directly; otherwise it compares the speed per node.
    Every engine/level pair runs in fresh processes. Per repetition, the baseline and the candidate run back to back in
    alternating order, so that each pair shares the machine's state; the median of the pairs' time ratios is the speedup,
    and their range shows the noise. Each process first warms the engine up with level-2 searches, so that the measured
    searches run optimized code rather than the JIT tiering of the first ones.
    The runs get dedicated cores, high priority and a fixed heap schedule, see isolation.js, so that the rest of the machine's load
    disturbs them as little as possible.
    Engines run in the process's own global scope rather than in a `vm` context, whose global lookups are slow.

    node scripts/hxconda/bench.js                  prints the results
    node scripts/hxconda/bench.js --record "label" also appends them to benchmark_results.md
*/
const path = require('path'), fs = require('fs'), os = require('os'), { execFileSync } = require('child_process');

const REFERENCE = path.join(__dirname, 'reference', 'position.js');
const CANDIDATE = path.join(__dirname, '..', '..', 'bin', 'hxconda.js');
const BASELINE = path.join(__dirname, 'baseline', 'hxconda.js');
const RESULTS = path.join(__dirname, 'benchmark_results.md');
const { BENCH_CORE_COUNT, TIMING_V8_FLAGS, dedicateTimingCores, raisePriority } = require('./isolation.js');
const LEVELS = [4, 5, 6];
const POSITION_COUNT = 10;
const POSITION_SEED = 42;
const REPETITIONS = 9;
const WARMUP_SEARCHES = 20;

if (process.argv[2] === '--single') {
    raisePriority();
    const { runInRealm, playoutPositions } = require('./harness.js');
    const [engine, level] = process.argv.slice(3);
    const request = (position, searchLevel) => engine === REFERENCE
        ? { command: 'bestMoveByLevel', position, level: searchLevel }
        : { kind: 'searchByLevel', position, level: searchLevel };
    const positions = playoutPositions(REFERENCE, POSITION_COUNT, POSITION_SEED);
    for (let i = 0; i < WARMUP_SEARCHES; i++)
        runInRealm(engine, request(positions[i % positions.length], 2), 1);
    let totalMs = 0;
    for (const [i, position] of positions.entries())
        totalMs += runInRealm(engine, request(position, +level), 500 + i).ms;
    console.log(totalMs);
    return;
}

dedicateTimingCores(BENCH_CORE_COUNT);
const single = (engine, level) => +execFileSync(process.execPath, [...TIMING_V8_FLAGS, __filename, '--single', engine, String(level)]).toString();

const median = values => values.slice().sort((a, b) => a - b)[values.length >> 1];
const rows = [];
for (const level of LEVELS) {
    const times = { reference: [], baseline: [], candidate: [] };
    const baselineRatios = [], referenceRatios = [];
    for (let i = 0; i < REPETITIONS; i++) {
        const reference = single(REFERENCE, level);
        let baseline, candidate;
        if (i % 2 === 0) {
            baseline = single(BASELINE, level);
            candidate = single(CANDIDATE, level);
        } else {
            candidate = single(CANDIDATE, level);
            baseline = single(BASELINE, level);
        }
        times.reference.push(reference);
        times.baseline.push(baseline);
        times.candidate.push(candidate);
        baselineRatios.push(baseline / candidate);
        referenceRatios.push(reference / candidate);
    }
    const [reference, baseline, candidate] = [median(times.reference), median(times.baseline), median(times.candidate)].map(Math.round);
    const row = {
        level, reference, baseline, candidate,
        vsBaseline: median(baselineRatios).toFixed(3),
        vsReference: median(referenceRatios).toFixed(2),
        range: `${Math.min(...baselineRatios).toFixed(3)}-${Math.max(...baselineRatios).toFixed(3)} (${baselineRatios.filter(ratio => ratio > 1).length}/${REPETITIONS} faster)`
    };
    rows.push(row);
    console.log(`level ${level}: reference ${reference} ms, baseline ${baseline} ms, candidate ${candidate} ms; candidate speedup x${row.vsBaseline} vs baseline (pairs x${row.range}), x${row.vsReference} vs reference`);
}

const labelIndex = process.argv.indexOf('--record');
if (labelIndex >= 0) {
    let commit = 'uncommitted';
    try { commit = execFileSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: __dirname }).toString().trim(); } catch (e) {}
    const date = new Date().toISOString().slice(0, 10);
    const label = process.argv[labelIndex + 1] ?? '';
    const cells = rows.map(r => `${r.reference} / ${r.baseline} / ${r.candidate}`).join(' | ');
    const speedups = [rows.map(r => r.vsBaseline).join(' / '), rows.map(r => r.range).join(' / '), rows.map(r => r.vsReference).join(' / ')].join(' | ');
    const machine = `${os.cpus()[0].model.trim()}, Node ${process.version}`;
    fs.appendFileSync(RESULTS, `| ${date} | ${commit} | ${label} | ${cells} | ${speedups} | ${machine} |\n`);
}
