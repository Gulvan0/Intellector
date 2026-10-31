import haxefolio.preferences.PreferenceRegistry;

class Preferences extends PreferenceRegistry
{
    public static final language = PreferenceRegistry.locale("general", "language");
    public static final followLatestMove = PreferenceRegistry.option("general", "follow_latest_move", ["always", "own_game_only", "never"], "own_game_only");
    public static final watchedGameOpening = PreferenceRegistry.option("general", "watched_game_opening", ["always", "unless_spectating", "never"], "unless_spectating");
    public static final silentChallenges = PreferenceRegistry.toggle("general", "silent_challenges", false);
    public static final premoveEnabled = PreferenceRegistry.toggle("game", "premoves", false);
    public static final autoPromote = PreferenceRegistry.option("game", "auto_promote", ["never", "shift", "always"], "shift");
    public static final boardControls = PreferenceRegistry.option("game", "board_controls", ["auto", "always", "never"], "auto");
    public static final clearAnnotationsOnClick = PreferenceRegistry.toggle("game", "clear_annotations_on_click", true);
    public static final clearAnnotationsOnPositionChange = PreferenceRegistry.toggle("game", "clear_annotations_on_position_change", true);
    public static final boardCoordinates = PreferenceRegistry.option("appearance", "board_coordinates", ["all", "files_only", "none"], "all");
    public static final annotationHexStyle = PreferenceRegistry.option("appearance", "annotation_hex_style", ["circle", "tint"], "circle");
    public static final variationView = PreferenceRegistry.option("appearance", "branching_type", ["tree", "plain_text"], "tree");
}
