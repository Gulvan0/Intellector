package net.shared.openings;

class Opening
{
    public final code:OpeningCode;
    public final shownToPlayersName:String;
    public final hiddenName:String;
    public final reminiscence:Bool;

    public function renderName(forPlayer:Bool):String
    {
        var codeStr:String = renderCode();
        var namePrefix:String = reminiscence? "RM " : "";
        var name:String = forPlayer? shownToPlayersName : hiddenName;
        var fullName:String = namePrefix + name;

        return '$codeStr. $fullName';
    }

    private function renderCode():String
    {
        //TODO: Fill
    }

    public function new(code:OpeningCode, shownToPlayersName:String, hiddenName:String, reminiscence:Bool) 
    {
        this.code = code;
        this.shownToPlayersName = shownToPlayersName;
        this.hiddenName = hiddenName;
        this.reminiscence = reminiscence;
    }
}