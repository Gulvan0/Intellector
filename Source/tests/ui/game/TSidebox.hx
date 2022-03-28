package tests.ui.game;

import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gfx.game.Sidebox;
import openfl.display.Sprite;

class TSidebox extends Sprite
{
    private var sidebox:Sidebox;

    private var testGamelogParserOutput:GameLogParserOutput;

    @steps(7)
    private function _seq_initializationTypes(i:Int) 
    {
        removeChild(sidebox);

        switch i
        {
            case 0: sidebox = new Sidebox(White, 600, 5, "PlayerWhite", "PlayerBlack", White);
            case 1: sidebox = new Sidebox(White, 600, 5, "PlayerWhite", "PlayerBlack", Black);
            case 2: sidebox = new Sidebox(Black, 600, 5, "PlayerWhite", "PlayerBlack", Black);
            case 3: sidebox = new Sidebox(Black, 600, 5, "PlayerWhite", "PlayerBlack", White);
            case 4: sidebox = new Sidebox(White, 600, 5, "PlayerWhite", "PlayerBlack", Black, testGamelogParserOutput);
            case 5: sidebox = new Sidebox(null, 600, 5, "PlayerWhite", "PlayerBlack", Black, testGamelogParserOutput);
            case 6: sidebox = new Sidebox(null, 80, 5, "PlayerWhite", "PlayerBlack", Black, testGamelogParserOutput);
            case 7: sidebox = new Sidebox(White, 600, 20, "PlayerWhite", "PlayerBlack", White);
            case 8: sidebox = new Sidebox(White, 600, 0, "PlayerWhite", "PlayerBlack", White);
        }

        addChild(sidebox);
    }

    //TODO: Handling Gameboard events

    //TODO: Handling net events

    //TODO: Separate makeMove testing for enemy moves - they need board's situation

    //TODO: Checklists for everything (specify tests for each initialization type)

    public function new()
    {
        super();
        testGamelogParserOutput = GameLogParser.parse("6620;\n3020Aggressor;1514;\n");
    }
}