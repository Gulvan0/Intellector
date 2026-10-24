package client.ui.analysis.study;

/** How the owner's edits of an open study stand against what the server has **/
enum StudySaveState
{
    Saved;
    Unsaved;
    Saving;
    /** The last save failed; the edits are still unsaved **/
    Failed;
}
