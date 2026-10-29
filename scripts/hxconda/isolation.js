/*
    Keeps the measurements apart from the rest of the machine's load. Windows only; elsewhere every function is a no-op.
    Timing runs (bench.js, match.js --time) get the topmost performance cores at high priority, one hyperthread of each,
    so that two engine threads never share a physical core. Runs whose results don't depend on timing (node-limited
    matches, compare.js) stay off the cores bench.js uses, at below-normal priority, so that they yield to the user's programs.
    Affinity is inherited by child processes; priority is not, so children call `raisePriority()` themselves.
*/
const os = require('os'), { execFileSync } = require('child_process');

const IS_WINDOWS = process.platform === 'win32';
/** Physical cores reserved for bench.js: its engine process and V8's background compiler and GC threads **/
const BENCH_CORE_COUNT = 2;
/** V8 flags of timing runs: the heap grows on a fixed schedule rather than by measured time, which load would shift **/
const TIMING_V8_FLAGS = ['--predictable-gc-schedule', '--min-semi-space-size=16', '--max-semi-space-size=16'];

const TOPOLOGY_SCRIPT = `
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public static class CpuSets {
    [DllImport("kernel32.dll")] static extern bool GetSystemCpuSetInformation(IntPtr info, uint length, out uint returned, IntPtr process, uint flags);
    public static string Describe() {
        uint length; GetSystemCpuSetInformation(IntPtr.Zero, 0, out length, IntPtr.Zero, 0);
        IntPtr buffer = Marshal.AllocHGlobal((int)length);
        GetSystemCpuSetInformation(buffer, length, out length, IntPtr.Zero, 0);
        var result = new System.Text.StringBuilder();
        for (int offset = 0; offset < length; offset += Marshal.ReadInt32(buffer, offset))
            result.AppendFormat("{0} {1} {2};", Marshal.ReadByte(buffer, offset + 14), Marshal.ReadByte(buffer, offset + 15), Marshal.ReadByte(buffer, offset + 18));
        return result.ToString();
    }
}
"@
[CpuSets]::Describe()`;

let topology = null;

// Physical cores, fastest efficiency class first and topmost index first within it; each lists its logical processors
function physicalCores() {
    if (topology != null)
        return topology;
    const cores = new Map();
    const description = execFileSync('powershell', ['-NoProfile', '-Command', TOPOLOGY_SCRIPT]).toString().trim();
    for (const entry of description.split(';').filter(entry => entry !== '')) {
        const [processor, core, efficiencyClass] = entry.split(' ').map(Number);
        if (!cores.has(core))
            cores.set(core, { core, efficiencyClass, processors: [] });
        cores.get(core).processors.push(processor);
    }
    topology = [...cores.values()].sort((a, b) => b.efficiencyClass - a.efficiencyClass || b.core - a.core);
    return topology;
}

function pin(processors, priorityClass) {
    const mask = processors.reduce((sum, processor) => sum + 2 ** processor, 0);
    execFileSync('powershell', ['-NoProfile', '-Command', `$p = Get-Process -Id ${process.pid}; $p.ProcessorAffinity = [IntPtr]${mask}; $p.PriorityClass = '${priorityClass}'`]);
}

/*
    Pins this process and its future children to one hyperthread of each of the `coreCount` fastest cores, at high priority;
    returns how many it got. With `coreCount` null, takes every performance core but the first, which the system's
    interrupts favour.
*/
function dedicateTimingCores(coreCount) {
    if (!IS_WINDOWS)
        return coreCount ?? Math.max(1, os.availableParallelism() - 1);
    const performanceCores = physicalCores().filter(core => core.efficiencyClass === physicalCores()[0].efficiencyClass);
    const fastest = performanceCores.slice(0, coreCount ?? Math.max(1, performanceCores.length - 1));
    pin(fastest.map(core => Math.min(...core.processors)), 'High');
    return fastest.length;
}

/** Moves this process and its future children off bench.js's cores, at below-normal priority; returns how many logical processors remain **/
function yieldToTimingRuns() {
    if (!IS_WINDOWS)
        return os.availableParallelism();
    const remaining = physicalCores().slice(BENCH_CORE_COUNT).flatMap(core => core.processors);
    pin(remaining, 'BelowNormal');
    return remaining.length;
}

/** High priority for a child process of a timing run **/
function raisePriority() {
    if (IS_WINDOWS)
        os.setPriority(os.constants.priority.PRIORITY_HIGH);
}

module.exports = { BENCH_CORE_COUNT, TIMING_V8_FLAGS, dedicateTimingCores, yieldToTimingRuns, raisePriority };
