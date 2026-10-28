package engine.hxconda.search;

enum abstract ProbeOutcome(Int)
{
    var Miss;
    /** The stored entries settle the score: read `cutoffScore` and `cutoffMove` **/
    var Cutoff;
    /** The stored bounds tighten the window: read `narrowedAlpha` and `narrowedBeta` **/
    var WindowNarrowed;
}
