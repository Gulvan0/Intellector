package client.ui.analysis.editor;

import client.GroupedLocaleResolvers.importPositionOverlay as phrase;
import client.logic.challenge.creation.ChallengeDraftRules;
import client.ui.common.board.BoardPreview;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxefolio.form.TextInputField;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/**
    The body of `ImportPositionOverlay`: the SIP field, validated on every edit, over a sunken inset
    with the board it describes. The inset keeps its size whether or not there is a board to show,
    and the field's message slot keeps its height whether or not there is an error, so nothing moves
    as the input changes. A SIP that parses shows its board even when it is not a valid starting
    position. Nothing is flagged while the field is empty.
**/
class ImportPositionForm extends VBox
{
    private final sipField:TextInputField;
    private final board:BoardPreview;
    private final onStateChange:Void->Void;

    private var parsed:Null<Position> = null;

    /** `onStateChange` is called after every edit, when `importablePosition` may have changed **/
    public function new(onSubmit:Void->Void, onStateChange:Void->Void)
    {
        super();

        this.onStateChange = onStateChange;
        this.percentWidth = 100;
        this.addClass(StyleClass.IMPORT_POSITION_BODY);

        sipField = new TextInputField(phrase("sip"), onSipEdited, onSubmit);
        sipField.selectAllOnFocus = true;
        sipField.addClass(StyleClass.IMPORT_POSITION_SIP);
        this.addComponent(sipField);

        var inset:Box = new Box();
        inset.percentWidth = 100;
        inset.height = insetHeight();
        inset.addClass(StyleClass.IMPORT_POSITION_INSET);
        this.addComponent(inset);

        board = new BoardPreview(Position.defaultStarting(), PieceColor.White, StyleVars.IMPORT_POSITION_BOARD_WIDTH);
        board.horizontalAlign = "center";
        inset.addComponent(board);

        refresh();
    }

    /** The position the field holds, if it is a valid starting one **/
    public function importablePosition():Null<Position>
    {
        return parsed != null && parsed.isValidStarting() ? parsed : null;
    }

    public function focus():Void
    {
        sipField.focus();
    }

    public function dispose():Void
    {
        sipField.dispose();
    }

    /** The height of the form's body, the field and the inset included **/
    public static function bodyHeight(messageLine:Int, fieldHeight:Int):Int
    {
        return 2 * StyleVars.IMPORT_POSITION_BODY_PADDING_VERTICAL
            + messageLine
            + StyleVars.SHARE_LABEL_GAP
            + fieldHeight
            + StyleVars.IMPORT_POSITION_SECTION_GAP
            + insetHeight();
    }

    private static function insetHeight():Int
    {
        return BoardPreview.heightFor(StyleVars.IMPORT_POSITION_BOARD_WIDTH) + 2 * StyleVars.IMPORT_POSITION_INSET_PADDING;
    }

    private function onSipEdited(_:String):Void
    {
        refresh();
        onStateChange();
    }

    private function refresh():Void
    {
        var text:String = StringTools.trim(sipField.currentText);
        parsed = text.length == 0 ? null : ChallengeDraftRules.parseSip(text);

        var errorKey:Null<String> = null;
        if (text.length > 0)
        {
            if (parsed == null)
                errorKey = "error.invalid_sip";
            else if (!parsed.isValidStarting())
                errorKey = "error.invalid_position";
        }

        sipField.invalid = errorKey != null;
        sipField.hint = errorKey != null ? phrase(errorKey) : phrase("hint");
        sipField.hintState = errorKey != null ? Error : Normal;

        board.hidden = parsed == null;
        if (parsed != null)
            board.setPosition(parsed);
    }
}
