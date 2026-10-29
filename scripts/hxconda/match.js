/*
    Self-play match between two engine builds, stopped by a sequential probability ratio test (SPRT).
    Every opening from openings.json is played twice, the candidate taking each color once. A game ends when an Intellector
    is captured or reaches its final row, on threefold repetition, or as a draw after MAX_PLIES plies.
    Searches are seeded, so a match is reproducible; with no noise, the variety comes from the openings alone.
    A --time match runs on dedicated cores with a fixed heap schedule, see isolation.js; any other match yields to the user's programs.

    node scripts/hxconda/match.js [options]
        --candidate <path>    default bin/hxconda.js
        --baseline <path>     default scripts/hxconda/baseline/hxconda.js; the reference engine works too with --level/--time
        --nodes <n>           node budget per move, Hxconda builds only (default 30000)
        --noise <amplitude>   evaluation noise with --nodes (default 0)
        --baseline-nodes <n>  a different node budget for the baseline, e.g. to calibrate what doubling the nodes is worth
        --level <0..10>       difficulty level per move instead of --nodes
        --time <ms>           thinking time per move instead of --nodes; counts speed gains, but is sensitive to machine load
        --elo0 <e> --elo1 <e> SPRT hypotheses: the candidate is <elo0> vs <elo1> Elo stronger (default 0 and 10)
        --alpha <a> --beta <b> SPRT error rates (default 0.05 each)
        --pairs <n>           stop after this many opening pairs (default: all openings)
        --threads <n>         parallel games (default: with --time, one per performance core but the first;
                              otherwise one per logical processor outside bench.js's cores)
        --record "<label>"    append the result to match_results.md

    node scripts/hxconda/match.js --generate-openings <count>
        Regenerates openings.json from bin/hxconda.js: 4-8 plies of a weak noisy search from the start,
        kept if a deeper search scores them within ±60.
*/
const path = require('path'), fs = require('fs'), { execFileSync, spawnSync } = require('child_process');
const { Worker, isMainThread, parentPort, workerData } = require('worker_threads');
const { runInRealm } = require('./harness.js');
const { TIMING_V8_FLAGS, dedicateTimingCores, yieldToTimingRuns } = require('./isolation.js');

const REFERENCE = path.join(__dirname, 'reference', 'position.js');
const OPENINGS = path.join(__dirname, 'openings.json');
const RESULTS = path.join(__dirname, 'match_results.md');
const MAX_PLIES = 400;
const PIECE_LETTERS = 'pPmMlLaAdDiIe';
const WHITE_FINAL_SQUARES = new Set([6, 19, 32, 45, 58]);
const BLACK_FINAL_SQUARES = new Set([0, 13, 26, 39, 52]);

// Game rules on the Anaconda notation

function winner(position) {
    const white = position.indexOf('i'), black = position.indexOf('I');
    if (white < 0)
        return 'black';
    if (black < 0)
        return 'white';
    if (WHITE_FINAL_SQUARES.has(white))
        return 'white';
    if (BLACK_FINAL_SQUARES.has(black))
        return 'black';
    return null;
}

function applyMove(position, move) {
    const cells = position.split('');
    const moving = cells[move.from], target = cells[move.to];
    const isWhiteToMove = cells[59] === 'w';
    if (moving === 'e' || (moving === moving.toLowerCase()) !== isWhiteToMove)
        throw new Error(`Illegal move ${JSON.stringify(move)} in ${position}`);

    if ((moving === 'i' && target === 'd') || (moving === 'I' && target === 'D')) {
        cells[move.from] = target;
        cells[move.to] = moving;
    } else {
        cells[move.from] = 'e';
        cells[move.to] = PIECE_LETTERS[move.resultingPiece];
    }
    cells[59] = isWhiteToMove ? 'b' : 'w';
    return cells.join('');
}

// Engines

function engine(enginePath, settings) {
    const isReference = fs.readFileSync(enginePath, 'utf8').includes('class Position');
    if (isReference && settings.mode === 'nodes')
        throw new Error('The reference engine supports --level and --time only');
    return { path: enginePath, isReference, settings };
}

// `history`: the game's positions before `position`, oldest first
function bestMove(player, position, seed, history) {
    const { mode, nodes, noise, level, time } = player.settings;
    if (player.isReference) {
        const request = mode === 'level' ? { command: 'bestMoveByLevel', position, level } : { command: 'bestMoveByTime', position, time };
        const posted = runInRealm(player.path, request, seed).posted;
        const result = posted[posted.length - 1];
        if (result == null || typeof result === 'string' || result.error || result.move == null)
            return null;
        return { from: result.move.from, to: result.move.to, resultingPiece: result.move.figure };
    }

    const request = mode === 'nodes' ? { kind: 'searchByNodes', position, history, nodeLimit: nodes, noiseAmplitude: noise }
        : mode === 'level' ? { kind: 'searchByLevel', position, history, level }
        : { kind: 'searchByTime', position, history, durationMs: time };
    const final = runInRealm(player.path, request, seed).posted.find(response => response.kind === 'completed' || response.kind === 'failed');
    return final != null && final.kind === 'completed' && final.report != null ? final.report.move : null;
}

// Plays one game; returns the points of `white`'s side
function playGame(opening, white, black, seed) {
    let position = opening;
    const visits = new Map([[position, 1]]);
    const history = [];

    for (let ply = 0; ; ply++) {
        const decided = winner(position);
        if (decided != null)
            return { whitePoints: decided === 'white' ? 1 : 0, plies: ply, reason: 'rules' };
        if (ply >= MAX_PLIES)
            return { whitePoints: 0.5, plies: ply, reason: 'length' };

        const move = bestMove(position[59] === 'w' ? white : black, position, seed + ply, history);
        if (move == null)
            return { whitePoints: 0.5, plies: ply, reason: 'no move' };

        history.push(position);
        position = applyMove(position, move);
        const count = (visits.get(position) ?? 0) + 1;
        visits.set(position, count);
        if (count >= 3)
            return { whitePoints: 0.5, plies: ply + 1, reason: 'repetition' };
    }
}

function playPair(pairIndex, opening, candidate, baseline) {
    const seed = 1 + pairIndex * 1000;
    const first = playGame(opening, candidate, baseline, seed);
    const second = playGame(opening, baseline, candidate, seed + 500);
    return { pairIndex, games: [{ ...first, candidatePoints: first.whitePoints }, { ...second, candidatePoints: 1 - second.whitePoints }] };
}

// Statistics

const logisticScore = elo => 1 / (1 + Math.pow(10, -elo / 400));
const scoreToElo = score => -400 * Math.log10(1 / Math.min(Math.max(score, 1e-6), 1 - 1e-6) - 1);

// Normalized generalized SPRT over pair scores (pentanomial model)
function statistics(pentanomial, options) {
    const pairCount = pentanomial.reduce((a, b) => a + b, 0);
    const mean = pentanomial.reduce((sum, count, points) => sum + count * points / 4, 0) / pairCount;
    const variance = pentanomial.reduce((sum, count, points) => sum + count * Math.pow(points / 4 - mean, 2), 0) / pairCount;
    const s0 = logisticScore(options.elo0), s1 = logisticScore(options.elo1);
    const llr = variance > 0 ? pairCount * (s1 - s0) * (2 * mean - s0 - s1) / (2 * variance) : 0;
    const margin = 1.96 * Math.sqrt(variance / pairCount);
    return {
        pairCount,
        llr,
        lowerBound: Math.log(options.beta / (1 - options.alpha)),
        upperBound: Math.log((1 - options.beta) / options.alpha),
        elo: scoreToElo(mean),
        eloLow: scoreToElo(mean - margin),
        eloHigh: scoreToElo(mean + margin)
    };
}

// Command line

function parseOptions(argv) {
    const options = {
        candidate: path.join(__dirname, '..', '..', 'bin', 'hxconda.js'),
        baseline: path.join(__dirname, 'baseline', 'hxconda.js'),
        mode: 'nodes', nodes: 30000, noise: 0, baselineNodes: null, level: null, time: null,
        elo0: 0, elo1: 10, alpha: 0.05, beta: 0.05,
        pairs: Infinity, threads: null, record: null
    };
    for (let i = 0; i < argv.length; i += 2) {
        const [name, value] = [argv[i].replace(/^--/, '').replace(/-(\w)/g, (_, letter) => letter.toUpperCase()), argv[i + 1]];
        if (name === 'candidate' || name === 'baseline' || name === 'record')
            options[name] = value;
        else if (name in options)
            options[name] = +value;
        else
            throw new Error(`Unknown option ${argv[i]}`);
        if (name === 'level' || name === 'time' || name === 'nodes')
            options.mode = name;
    }
    return options;
}

const baselineSettings = options => options.baselineNodes != null ? { ...options, nodes: options.baselineNodes } : options;

function conditions(options) {
    const budget = options.mode === 'nodes' ? `${options.nodes}${options.baselineNodes != null ? ` vs ${options.baselineNodes}` : ''} nodes, noise ${options.noise}` : options.mode === 'level' ? `level ${options.level}` : `${options.time} ms`;
    return `${budget}; SPRT [${options.elo0}, ${options.elo1}], α=${options.alpha}, β=${options.beta}`;
}

const STARTING_POSITION = 'mpeeePMleeeeLapeeePAdeeeeDipeeePIdeeeeDapeeePAleeeeLmpeeePMw';
const OPENING_MOVE_NODES = 2000, OPENING_MOVE_NOISE = 150, OPENING_CHECK_NODES = 10000, OPENING_SCORE_LIMIT = 60;

// One candidate opening: 4-8 plies of a weak, noisy search from the start, kept if a deeper search finds it balanced
function candidateOpening(enginePath, seed) {
    const player = engine(enginePath, { mode: 'nodes', nodes: OPENING_MOVE_NODES, noise: OPENING_MOVE_NOISE });
    let position = STARTING_POSITION;
    const plies = 4 + seed % 5;
    for (let ply = 0; ply < plies; ply++) {
        const move = bestMove(player, position, seed * 16 + ply, []);
        if (move == null)
            return null;
        position = applyMove(position, move);
        if (winner(position) != null)
            return null;
    }
    const check = runInRealm(enginePath, { kind: 'searchByNodes', position, nodeLimit: OPENING_CHECK_NODES, noiseAmplitude: 0 }, seed).posted.find(r => r.kind === 'completed');
    return check != null && check.report != null && Math.abs(check.report.score) <= OPENING_SCORE_LIMIT ? position : null;
}

function generateOpenings(count, threads) {
    const enginePath = path.join(__dirname, '..', '..', 'bin', 'hxconda.js');
    const openings = new Set();
    let nextSeed = 1, done = false;
    const workers = [];
    for (let i = 0; i < threads; i++) {
        const worker = new Worker(__filename, { workerData: { task: 'openings', enginePath } });
        worker.on('message', position => {
            if (done)
                return;
            if (position != null)
                openings.add(position);
            if (openings.size < count)
                worker.postMessage(nextSeed++);
            else {
                done = true;
                workers.forEach(w => w.terminate());
                fs.writeFileSync(OPENINGS, JSON.stringify([...openings].slice(0, count), null, 1) + '\n');
                console.log(`${count} openings written to ${OPENINGS} out of ${nextSeed - 1} candidates`);
            }
        });
        workers.push(worker);
        worker.postMessage(nextSeed++);
    }
}

function runMatch(options) {
    if (options.mode === 'time' && !TIMING_V8_FLAGS.every(flag => process.execArgv.includes(flag)))
        process.exit(spawnSync(process.execPath, [...TIMING_V8_FLAGS, __filename, ...process.argv.slice(2)], { stdio: 'inherit' }).status);
    options.threads = options.mode === 'time' ? dedicateTimingCores(options.threads) : Math.min(options.threads ?? Infinity, yieldToTimingRuns());

    const openings = JSON.parse(fs.readFileSync(OPENINGS, 'utf8'));
    const pairLimit = Math.min(options.pairs, openings.length);
    engine(options.candidate, options);
    engine(options.baseline, baselineSettings(options));

    console.log(`${path.basename(options.candidate)} vs ${path.relative(process.cwd(), options.baseline)}: ${conditions(options)}; up to ${pairLimit} pairs on ${options.threads} threads`);

    const pentanomial = [0, 0, 0, 0, 0];
    const outcomes = { wins: 0, draws: 0, losses: 0 };
    const endings = {};
    let nextPair = 0, finished = 0, verdict = null, plies = 0;
    const started = Date.now();
    const workers = [];

    const finish = () => {
        workers.forEach(worker => worker.terminate());
        const stats = statistics(pentanomial, options);
        const minutes = ((Date.now() - started) / 60000).toFixed(1);
        verdict ??= 'inconclusive';
        const summary = [
            `Verdict: ${verdict} after ${stats.pairCount} pairs (${2 * stats.pairCount} games, ${minutes} min, ${Math.round(plies / (2 * stats.pairCount))} plies per game)`,
            `Candidate W/D/L ${outcomes.wins}/${outcomes.draws}/${outcomes.losses}, pair points 0/0.5/1/1.5/2: ${pentanomial.join('/')}`,
            `Elo ${stats.elo.toFixed(1)} [${stats.eloLow.toFixed(1)}, ${stats.eloHigh.toFixed(1)}], LLR ${stats.llr.toFixed(2)} [${stats.lowerBound.toFixed(2)}, ${stats.upperBound.toFixed(2)}]`,
            `Game endings: ${Object.entries(endings).map(([reason, count]) => `${reason} ${count}`).join(', ')}`
        ];
        console.log(summary.join('\n'));

        if (options.record != null) {
            let commit = 'uncommitted';
            try { commit = execFileSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: __dirname }).toString().trim(); } catch (e) {}
            const row = [
                new Date().toISOString().slice(0, 10), commit, options.record, conditions(options), stats.pairCount,
                `${outcomes.wins}/${outcomes.draws}/${outcomes.losses}`, pentanomial.join('/'),
                `${stats.elo.toFixed(1)} [${stats.eloLow.toFixed(1)}, ${stats.eloHigh.toFixed(1)}]`, stats.llr.toFixed(2), verdict
            ];
            fs.appendFileSync(RESULTS, `| ${row.join(' | ')} |\n`);
        }
    };

    const dispatch = worker => {
        if (verdict == null && nextPair < pairLimit) {
            worker.postMessage(nextPair);
            nextPair++;
        }
    };

    const onPair = (worker, result) => {
        if (verdict != null)
            return;
        finished++;
        let pairPoints = 0;
        for (const game of result.games) {
            pairPoints += game.candidatePoints;
            plies += game.plies;
            endings[game.reason] = (endings[game.reason] ?? 0) + 1;
            if (game.candidatePoints === 1)
                outcomes.wins++;
            else if (game.candidatePoints === 0)
                outcomes.losses++;
            else
                outcomes.draws++;
        }
        pentanomial[pairPoints * 2]++;

        const stats = statistics(pentanomial, options);
        if (stats.llr >= stats.upperBound)
            verdict = `accepted: stronger by more than ${options.elo0} Elo`;
        else if (stats.llr <= stats.lowerBound)
            verdict = `rejected: not stronger by ${options.elo1} Elo`;

        if (finished % 20 === 0 || verdict != null)
            console.log(`  ${finished} pairs: W/D/L ${outcomes.wins}/${outcomes.draws}/${outcomes.losses}, Elo ${stats.elo.toFixed(1)} [${stats.eloLow.toFixed(1)}, ${stats.eloHigh.toFixed(1)}], LLR ${stats.llr.toFixed(2)}`);

        if (verdict != null || finished === pairLimit)
            finish();
        else
            dispatch(worker);
    };

    for (let i = 0; i < Math.min(options.threads, pairLimit); i++) {
        const worker = new Worker(__filename, { workerData: { options, openings } });
        worker.on('message', result => onPair(worker, result));
        worker.on('error', error => { console.error(error); process.exit(1); });
        workers.push(worker);
        dispatch(worker);
    }
}

if (!isMainThread && workerData.task === 'openings')
    parentPort.on('message', seed => parentPort.postMessage(candidateOpening(workerData.enginePath, seed)));
else if (!isMainThread) {
    const { options, openings } = workerData;
    const candidate = engine(options.candidate, options), baseline = engine(options.baseline, baselineSettings(options));
    parentPort.on('message', pairIndex => parentPort.postMessage(playPair(pairIndex, openings[pairIndex], candidate, baseline)));
} else if (process.argv[2] === '--generate-openings')
    generateOpenings(+process.argv[3], yieldToTimingRuns());
else
    runMatch(parseOptions(process.argv.slice(2)));
