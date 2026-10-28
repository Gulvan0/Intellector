// Runs engine workers inside Node `vm` contexts, with a seeded Math.random and an optionally mocked performance.now.
const vm = require('vm'), fs = require('fs'), util = require('util');

const PRNG = seed => `Math.random = (function (a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; var t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; })(${seed});`;

const scripts = {};
const load = path => scripts[path] ??= new vm.Script(fs.readFileSync(path, 'utf8'), { filename: path });

// Posts one message to the worker script at `path`; clockStep = null uses the real clock
function runWorker(path, request, seed, clockStep) {
    const posted = [];
    const ctx = vm.createContext({ console: { log() {} } });
    ctx.self = ctx;
    ctx.postMessage = message => posted.push(structuredClone(message));
    if (clockStep == null)
        ctx.performance = performance;
    else {
        let time = 0;
        ctx.performance = { now: () => (time += clockStep) };
    }
    vm.runInContext(PRNG(seed), ctx);
    load(path).runInContext(ctx);

    const started = performance.now();
    try { ctx.onmessage({ data: request }); }
    catch (e) { posted.push({ error: true }); }
    return { posted, ms: performance.now() - started };
}

/*
    Same as `runWorker` with the real clock, but runs the scripts in this thread's own global scope, which is much faster
    than a `vm` context. Each script loads once and handles every later request. Both engines rebuild all search state per
    request, and Math.random is reseeded, so the results are identical to `runWorker`'s. The reference engine declares
    top-level classes, so a thread can load it only once.
*/
const realmHandlers = {};
let realmPosted = [];
let realmRandomState = 0;
function runInRealm(path, request, seed) {
    if (Object.keys(realmHandlers).length === 0) {
        globalThis.self = globalThis;
        globalThis.postMessage = message => realmPosted.push(structuredClone(message));
        Math.random = function () {
            realmRandomState |= 0;
            realmRandomState = realmRandomState + 0x6D2B79F5 | 0;
            let t = Math.imul(realmRandomState ^ realmRandomState >>> 15, 1 | realmRandomState);
            t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
            return ((t ^ t >>> 14) >>> 0) / 4294967296;
        };
    }
    if (realmHandlers[path] == null) {
        const silencedLog = console.log;
        console.log = () => {};
        globalThis.onmessage = null;
        vm.runInThisContext(fs.readFileSync(path, 'utf8'), { filename: path });
        realmHandlers[path] = globalThis.onmessage;
        console.log = silencedLog;
    }

    realmPosted = [];
    realmRandomState = seed;
    const started = performance.now();
    const silencedLog = console.log;
    console.log = () => {};
    try { realmHandlers[path]({ data: request }); }
    catch (e) { realmPosted.push({ error: true }); }
    finally { console.log = silencedLog; }
    return { posted: realmPosted, ms: performance.now() - started };
}

// Requests and responses use the reference protocol: {command: "bestMoveByLevel" | "bestMoveByTime", position, level | time}
const runReference = runWorker;

// Same as `runReference`, translating to and from the Hxconda protocol
function runPort(path, request, seed, clockStep) {
    const isTimed = request.command === 'bestMoveByTime';
    const portRequest = isTimed
        ? { kind: 'searchByTime', position: request.position, durationMs: request.time }
        : { kind: 'searchByLevel', position: request.position, level: request.level };
    const result = runWorker(path, portRequest, seed, clockStep);
    result.posted = result.posted.map(response => toReferenceMessage(response, isTimed));
    return result;
}

function toReferenceMessage(response, isTimed) {
    switch (response.kind) {
        case 'progress': return response.percent + '%';
        case 'iteration': return toReferenceReport(response.report);
        case 'completed': return isTimed ? { ...toReferenceReport(response.report), completed: true } : toReferenceReport(response.report);
        case 'failed': return { error: true };
        default: return { unexpected: response };
    }
}

function toReferenceReport(report) {
    if (report == null)
        return {};
    const move = m => ({ from: m.from, to: m.to, figure: m.resultingPiece });
    const message = { move: report.move == null ? undefined : move(report.move), mark: report.score, depth: report.depth, progress: report.searchedRootMoveCount };
    if (report.principalLine != null)
        message.bestLine = report.principalLine.map(move).reverse();
    return message;
}

// Random playout positions generated with the reference engine's move generator
function playoutPositions(referencePath, count, seed) {
    const ctx = vm.createContext({ console: { log() {} } });
    ctx.self = ctx;
    vm.runInContext(PRNG(seed), ctx);
    load(referencePath).runInContext(ctx);
    return vm.runInContext(`(function (count) {
        const result = [];
        while (result.length < count) {
            const p = new Position();
            const plies = Math.floor(Math.random() * 70);
            for (let i = 0; i < plies && p.winMark() === false; i++) {
                const moves = p.getMoves();
                if (moves.length === 0)
                    break;
                p.engineMove(moves[Math.floor(Math.random() * moves.length)]);
            }
            result.push(p.toString());
        }
        return result;
    })(${count})`, ctx);
}

// Deep equality that also tells undefined-valued keys and key order apart
const same = (a, b) => util.isDeepStrictEqual(a, b) && JSON.stringify(a) === JSON.stringify(b);

module.exports = { runWorker, runInRealm, runReference, runPort, playoutPositions, same };
