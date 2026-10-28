/*
    Checks that the Haxe engine (bin/hxconda.js, built by `haxe hxconda.hxml`) posts exactly the same messages as the reference
    Anaconda engine, once translated to the reference protocol.
    Both run with the same seeded Math.random and a mocked performance.now that advances by a fixed step per call.

    node scripts/hxconda/compare.js level <positionCount> <seed> <levels, e.g. 0,1,2,3> [--baseline]
    node scripts/hxconda/compare.js time <positionCount> <seed> <milliseconds, e.g. 50,200> [--baseline]

    --baseline compares against the last accepted build (baseline/hxconda.js) instead of the reference engine.
*/
const path = require('path');
const { runReference, runPort, playoutPositions, same } = require('./harness.js');

const REFERENCE = path.join(__dirname, 'reference', 'position.js');
const PORT = path.join(__dirname, '..', '..', 'bin', 'hxconda.js');
const BASELINE = path.join(__dirname, 'baseline', 'hxconda.js');
const CLOCK_STEP = 0.004;

const [mode, positionCount, seedArg, values] = process.argv.slice(2);
const againstBaseline = process.argv.includes('--baseline');
const runExpected = (request, seed) => againstBaseline ? runPort(BASELINE, request, seed, CLOCK_STEP) : runReference(REFERENCE, request, seed, CLOCK_STEP);
const positions = playoutPositions(REFERENCE, +positionCount, +seedArg);
const malformed = ['', 'garbage', positions[0].slice(0, 59) + 'x', 'e'.repeat(59) + 'w', 'i' + 'e'.repeat(57) + 'Iw', 'ii' + 'e'.repeat(56) + 'Iw', 'e'.repeat(6) + 'i' + 'e'.repeat(51) + 'Iw'];

let cases = 0, messages = 0, erroring = 0, mismatches = 0;
for (const [index, position] of [...positions, ...(mode === 'level' ? malformed : [])].entries())
    for (const value of values.split(',').map(Number)) {
        const request = mode === 'level' ? { command: 'bestMoveByLevel', position, level: value } : { command: 'bestMoveByTime', position, time: value };
        const seed = 1000 + index * 31 + value;
        const expected = runExpected(request, seed).posted;
        const actual = runPort(PORT, request, seed, CLOCK_STEP).posted;

        cases++;
        messages += expected.length;
        if (expected.some(message => message && message.error))
            erroring++;
        if (same(expected, actual))
            continue;

        mismatches++;
        if (mismatches <= 5) {
            const k = expected.findIndex((message, i) => !same(message, actual[i]));
            console.log(`MISMATCH position=${position} ${mode}=${value} at message ${k} (${expected.length} vs ${actual.length} messages)`);
            console.log('  expected:', JSON.stringify(expected[k]).slice(0, 400));
            console.log('  actual:  ', JSON.stringify(actual[k]).slice(0, 400));
        }
    }

console.log(`${mode} vs ${againstBaseline ? 'baseline' : 'reference'}: ${cases} cases, ${messages} messages, ${erroring} erroring cases, ${mismatches} mismatches`);
process.exitCode = mismatches > 0 ? 1 : 0;
