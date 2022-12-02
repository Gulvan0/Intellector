package net.shared.board;

enum PerformPlyResult
{
    NormalPlyPerformed(ply:MaterializedPly);
    ProgressivePlyPerformed(ply:MaterializedPly);
    MateReached;
    BreakthroughReached;
    FailedToPerform;
}