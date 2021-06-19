package openings;

import dict.Dictionary;
import struct.PieceType;

class Branch
{
    public var name:String;
    public var move:String;
    public var successors:Map<String, Branch>;
    public var terminal:Bool;

    public function get(move:String):Branch
    {
        var exactMove = successors.get(move);
        var otherMove = successors.get("");
        return exactMove != null? exactMove : otherMove != null? otherMove : new Branch(name, "", []);
    }

    public function new(name:String, move:String, packedSuccessors:Array<Array<Branch>>) 
    {
        this.name = name;
        this.move = move;
        var unpackedSuccessors:Array<Branch> = [];
        for (bunch in packedSuccessors)
            for (successor in bunch)
                unpackedSuccessors.push(successor);
        this.successors = [for (b in unpackedSuccessors) b.move => b];
        this.terminal = Lambda.empty(successors);
    }
}

class OpeningTree 
{
    public static var root:Branch;

    public var currentNode:Branch;
    public var isMirrored:Null<Bool>;

    public function makeMove(fromI:Int, fromJ:Int, toI:Int, toJ:Int, ?morphInto:PieceType) 
    {
        if (isMirrored == null)
            if (fromI == 4)
                if (toI == 4)
                    isMirrored = null;
                else 
                    isMirrored = toI > 5;
            else 
                isMirrored = fromI > 5;
        if (isMirrored == true)
        {
            fromI = 8 - fromI;
            toI = 8 - toI;
        }
        var collapsedMove:String = '$fromI$fromJ$toI$toJ' + (morphInto == null? "" : morphInto.getName());
        currentNode = currentNode.get(collapsedMove);
    }

    public function new() 
    {
        currentNode = root;
    }

    public static function init() 
    {
        root = new Branch(Dictionary.getPhrase(OPENING_STARTING_POSITION), "",
        [
            [new Branch("C00. Central Advancement", "4544", 
            [
                [new Branch("C00. Central Advancement", "", 
                [
                    [new Branch("C06. Bongcloud Opening", "4645", [])]
                ])]
            ])],
            [new Branch("C01. Open Game", "4534", [])],
            [new Branch("C02. Flank Game", "2534", [])],
            [new Branch("C03. Deflected Progressor Opening", "2514", [])],
            [new Branch("C04. Canal Opening", "0514", 
            [
                [new Branch("C05. Canal Opening, Twist Counterattack", "6071", 
                [
                    [new Branch("C05. Canal Opening, Twist Counterattack, Tense Defense", "6654", [])],
                    [new Branch("C05. Canal Opening, Twist Counterattack, Boulder Defense", "7554", [])],
                    pack("C05. Canal Opening, Twist Counterattack Evaded", ["4635","4655","3546","5546"], [])
                ])],
                [new Branch("C06. Canal Opening, Overload Counterattack", "2011", 
                [
                    [new Branch("C06. Canal Opening, Overload Counterattack, Tense Defense", "2634", [])],
                    [new Branch("C06. Canal Opening, Overload Counterattack, Boulder Defense", "1534", [])],
                    pack("C06. Canal Opening, Overload Counterattack Evaded", ["4635","4655","3546","5546"], [])
                ])],
                [new Branch("C07. Canal Opening, Central Counterattack", "6051", [])],
                [new Branch("C08. Canal Opening, Exchange Invitation", "0111", 
                [
                    [new Branch("C08. Canal Opening, Exchange Invitation Accepted", "0600", 
                    [
                        [new Branch("C08. Canal Opening, Exchange Variation", "2000", 
                        [
                            [new Branch("C09. Venetian Game", "8574", 
                            [
                                [new Branch("C09. Venetian Game, Exchange Invitation", "8171", 
                                [
                                    [new Branch("C09. Venetian Game, Exchange Invitation Accepted", "8680", 
                                    [
                                        [new Branch("C10. Dominatorless Game", "6080", [])]
                                    ])],
                                    [new Branch("C09. Venetian Game, Exchange Declined", "", [])]
                                ])]
                            ])]
                        ])]
                    ])],
                    [new Branch("C08. Canal Opening, Exchange Declined", "", [])]
                ])],
            ])],
            [new Branch("C11. Ware Opening", "0504", [])],
            [new Branch("A00. Aggressor Sac", "2660", 
            [
                [new Branch("A01. Morph Variant", "5060Aggressor", 
                [
                    [new Branch("A01. Double Aggressor Sac", "6620", 
                    [
                        [new Branch("A03. Aggressor-Defensor Confrontation", "3020Aggressor", [])],
                        [new Branch("A04. Double Aggressor Sac, Asymmetrical Variation", "3020", [])],
                        pack("A01. Double Aggressor Sac, Coward Variation", ["4030","4050", "3040","5040"], []),
                        [new Branch("A01. Deferred Fool's Mate", "", [])]
                    ])]
                ])],
                [new Branch("A02. Capture Variant", "5060", 
                [
                    [new Branch("A02. Double Aggressor Sac", "6620", 
                    [
                        [new Branch("A04. Double Aggressor Sac, Asymmetrical Variation", "3020Aggressor", [])],
                        [new Branch("A05. Double Aggressor Sac, Deflected Defensors Variation", "3020", [])],
                        pack("A02. Double Aggressor Sac, Coward Variation", ["4030","4050", "3040","5040"], []),
                        [new Branch("A02. Deferred Fool's Mate", "", [])]
                    ])]
                ])],
                pack("A00. Intellector Escape", ["4030","4050", "3040","5040"], []),
                [new Branch("A00. Fool's Mate", "", [])]
            ])],
            [new Branch("A06. Flank Attack", "2614", 
            [
                [new Branch("A07. Flank Attack, Tense Defense", "2031", [])],
                [new Branch("A08. Flank Attack, Boulder Defense", "1031", [])],
                [new Branch("A09. Flank Attack, Flank Wall", "4131", [])],
                [new Branch("A10. Flank Attack, Central Wall", "2131", [])],
                pack("A11. Flank Attack Evaded", ["4030","4050", "3040","5040"], []),
                [new Branch("A06. Flank Attack, Scholar's Mate", "", [])]
            ])],
            [new Branch("A12. Central Attack", "2634", 
            [
                [new Branch("A13. Central Attack, Linear Defense", "2011", [])],
                [new Branch("A14. Central Attack, Step Defense", "1011", [])],
                [new Branch("A15. Central Attack, Canal Defense", "0111", [])],
                [new Branch("A16. Central Attack, Wing Defense", "2111", [])],
                [new Branch("A17. Central Attack, Exchange Variation", "6034", [])],
                [new Branch("A18. Central Attack, Dominator Blunder", "", [])]
            ])],
            [new Branch("B00. Jump Opening", "1513", 
            [
                [new Branch("B00. Pillar Opening", "1012", [])]
            ])],
            [new Branch("B01. Cannon Opening", "1514", [])],
            [new Branch("B02. Reti Opening", "1534", 
            [
                [new Branch("B02. Reti Opening", "", 
                [
                    [new Branch("B03. Mexican Opening", "7554", [])],
                    [new Branch("B04. Generalist Opening", "6654", [])]
                ])]
            ])],
            [new Branch("D00. Wayward Defensor Opening", "3534", [])],
            pack("D01. Accelerated Bongcloud", ["4635", "3546"], []),
        ]);
    }

    private static function pack(name:String, moves:Array<String>, packedSuccessors:Array<Array<Branch>>) 
    {
        var bunch = [];
        for (move in moves)
            bunch.push(new Branch(name, move, packedSuccessors));
        return bunch;
    }

    public static function mirror(move:String):String
    {
        var fromI = move.charAt(0);
        var fromJ = move.charAt(1);
        var toI = move.charAt(2);
        var toJ = move.charAt(3);
        var rest = move.substr(4);
        return '${8 - Std.parseInt(fromI)}$fromJ${8 - Std.parseInt(toI)}$toJ' + rest;
    }
}