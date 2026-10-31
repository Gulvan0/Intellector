package client.botengine;

import client.datatypes.bot.BotSettings;
import intellectorboard.position.Position;

/** The bot's turn in a game **/
class BotMoveRequest
{
    /** The game's positions, oldest first: the bot moves in the last one **/
    public final positions:Array<Position>;
    public final settings:BotSettings;
    /** What the bot's clock allows for the move, see `BotTimeAllocation`; null for an untimed game **/
    public final allocationSeconds:Null<Float>;

    public function new(positions:Array<Position>, settings:BotSettings, allocationSeconds:Null<Float>)
    {
        this.positions = positions;
        this.settings = settings;
        this.allocationSeconds = allocationSeconds;
    }

    public function plyCount():Int
    {
        return positions.length - 1;
    }

    public function position():Position
    {
        return positions[positions.length - 1];
    }
}
