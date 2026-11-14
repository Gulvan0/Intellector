package net.models.game.archive;

import jsonmodel.IJsonUnserializableMacro;
import morestd.DateTime;
import net.models.game.OutcomeKind;
import net.models.game.PlayerRatingPublic;
import net.models.common.PieceColor;
import net.models.common.TimeControlKind;
import net.models.common.UserRefWithNickname;

class ArchiveGameRow implements IJsonUnserializableMacro
{
    public var id:Int;
    public var white_player:UserRefWithNickname;
    public var black_player:UserRefWithNickname;
    @:default(null) public var white_rating:Null<PlayerRatingPublic>;
    @:default(null) public var black_rating:Null<PlayerRatingPublic>;
    @:default(null) @:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var started_at:Null<DateTime>;
    @:default(null) @:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var ended_at:Null<DateTime>;
    @:default(null) public var duration_ms:Null<Float>;
    public var time_control_kind:TimeControlKind;
    @:default(null) public var start_seconds:Null<Int>;
    @:default(null) public var increment_seconds:Null<Int>;
    public var rated:Bool;
    @:default(null) public var custom_starting_sip:Null<String>;
    @:default(null) public var opening_id:Null<Int>;
    public var ended:Bool;
    @:default(null) public var outcome_kind:Null<OutcomeKind>;
    @:default(null) public var winner:Null<PieceColor>;
    public var move_count:Int;
    @:default(null) public var white_time_left_ms:Null<Float>;
    @:default(null) public var black_time_left_ms:Null<Float>;
}
