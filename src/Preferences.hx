import haxefolio.preferences.PreferenceRegistry;

class Preferences extends PreferenceRegistry
{
    public static final language = PreferenceRegistry.locale("general", "language");
    public static final boardCoordinates = PreferenceRegistry.option("general", "board_coordinates", ["all", "files_only", "none"], "all");
    public static final premoveEnabled = PreferenceRegistry.toggle("general", "premoves", false);
    public static final branchingTabType = PreferenceRegistry.option("general", "branching_type", ["tree", "outline", "plain_text"], "tree");
    public static final branchingTurnColorIndicators = PreferenceRegistry.toggle("general", "branching_turn_color_indicators", true);
    public static final silentChallenges = PreferenceRegistry.toggle("general", "silent_challenges", false);
    public static final followLatestMove = PreferenceRegistry.option("general", "follow_latest_move", ["always", "own_game_only", "never"], "own_game_only");
}
