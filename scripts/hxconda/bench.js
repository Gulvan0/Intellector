/*
    Speed benchmark of node-limited searches: the candidate (bin/hxconda.js) against the last accepted build
    (baseline/hxconda.js) and the reference Anaconda engine. Builds with the same behaviour visit the same nodes, so wall
    time compares the implementations directly; otherwise it compares the speed per node.
    Every engine/level pair runs in fresh processes, interleaving the engines so machine drift hits all of them alike;
    the median of the repetitions counts.
    Engines run in the process's own global scope rather than in a `vm` context, whose global lookups are slow.

    node scripts/hxconda/bench.js                  prints the results
    node scripts/hxconda/bench.js --record "label" also appends them to benchmark_results.md
*/
const path = require('path'), fs = require('fs'), os = require('os'), { execFileSync } = require('child_process');

const REFERENCE = path.join(__dirname, 'reference', 'position.js');
const CANDIDATE = path.join(__dirname, '..', '..', 'bin', 'hxconda.js');
const BASELINE = path.join(__dirname, 'baseline', 'hxconda.js');
const RESULTS = path.join(__dirname, 'benchmark_results.md');
const LEVELS = [4, 5, 6];
const POSITION_COUNT = 10;
const POSITION_SEED = 42;
const REPETITIONS = 5;

if (process.argv[2] === '--single') {
    const { runInRealm, playoutPositions } = require('./harness.js');
    const [engine, level] = process.argv.slice(3);
    const request = (position, searchLevel) => engine === REFERENCE
        ? { command: 'bestMoveByLevel', position, level: searchLevel }
        : { kind: 'searchByLevel', position, level: searchLevel };
    const positions = playoutPositions(REFERENCE, POSITION_COUNT, POSITION_SEED);
    runInRealm(engine, request(positions[0], 2), 1);
    let totalMs = 0;
    for (const [i, position] of positions.entries())
        totalMs += runInRealm(engine, request(position, +level), 500 + i).ms;
    console.log(totalMs);
    return;
}

const single = (engine, level) => +execFileSync(process.execPath, [__filename, '--single', engine, String(level)]).toString();

const median = values => values.slice().sort((a, b) => a - b)[values.length >> 1];
const rows = [];
for (const level of LEVELS) {
    const times = { reference: [], baseline: [], candidate: [] };
    for (let i = 0; i < REPETITIONS; i++) {
        times.reference.push(single(REFERENCE, level));
        times.baseline.push(single(BASELINE, level));
        times.candidate.push(single(CANDIDATE, level));
    }
    const [reference, baseline, candidate] = [median(times.reference), median(times.baseline), median(times.candidate)].map(Math.round);
    const row = { level, reference, baseline, candidate, vsBaseline: (baseline / candidate).toFixed(3), vsReference: (reference / candidate).toFixed(2) };
    rows.push(row);
    console.log(`level ${level}: reference ${reference} ms, baseline ${baseline} ms, candidate ${candidate} ms; candidate speedup x${row.vsBaseline} vs baseline, x${row.vsReference} vs reference`);
}

const labelIndex = process.argv.indexOf('--record');
if (labelIndex >= 0) {
    let commit = 'uncommitted';
    try { commit = execFileSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: __dirname }).toString().trim(); } catch (e) {}
    const date = new Date().toISOString().slice(0, 10);
    const label = process.argv[labelIndex + 1] ?? '';
    const cells = rows.map(r => `${r.reference} / ${r.baseline} / ${r.candidate}`).join(' | ');
    const speedups = [rows.map(r => r.vsBaseline).join(' / '), rows.map(r => r.vsReference).join(' / ')].join(' | ');
    const machine = `${os.cpus()[0].model.trim()}, Node ${process.version}`;
    fs.appendFileSync(RESULTS, `| ${date} | ${commit} | ${label} | ${cells} | ${speedups} | ${machine} |\n`);
}
