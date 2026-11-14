package client.ui.games;

import client.datatypes.games.SortLevel;
import client.formatters.ArchiveFormatters;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.structure.ActionBar;
import haxefolio.structure.ActionButton;

using client.ui.ComponentExtension;

/** The export options: what the file will hold, and whether to append the move columns **/
class ExportOverlay
{
    private static inline final BODY_HEIGHT:Int = 196;

    /** `onExport` gets whether to include the move columns **/
    public static function present(gameCount:Int, columnCount:Int, sort:Array<SortLevel>, onExport:Bool->Void):Void
    {
        HaxeFolioApp.present("export-games", dismiss -> {
            var includeMoves:Bool = false;

            var content:VBox = new VBox();
            content.percentWidth = 100;
            content.addClass(StyleClass.GAMES_EXPORT_CONTENT);

            var summary:VBox = new VBox();
            summary.percentWidth = 100;
            summary.addClass(StyleClass.GAMES_EXPORT_SUMMARY);
            summary.addComponent(summaryRow("intellector.games.export.games", () -> Std.string(gameCount)));
            summary.addComponent(summaryRow("intellector.games.export.columns", () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.export.columns_value", Std.string(columnCount)))));
            summary.addComponent(summaryRow("intellector.games.export.sort", () -> sortText(sort)));
            content.addComponent(summary);

            var option:HBox = new HBox();
            option.percentWidth = 100;
            option.addClass(StyleClass.FILTER_OPTION);
            option.trackHover();
            var box:Box = new Box();
            box.addClass(StyleClass.FILTER_CHECKBOX);
            box.verticalAlign = "center";
            var check:Image = new Image();
            check.resource = Assets.controlIcon("check");
            check.width = 10;
            check.height = 10;
            check.horizontalAlign = "center";
            check.verticalAlign = "center";
            box.addComponent(check);
            option.addComponent(box);
            var optionLabel:Label = new Label();
            optionLabel.percentWidth = 100;
            optionLabel.text = LocaleUtils.localeBinding("intellector.games.export.moves");
            optionLabel.addClass(StyleClass.FILTER_OPTION_CAPTION);
            optionLabel.verticalAlign = "center";
            option.addComponent(optionLabel);
            option.registerEvent(MouseEvent.CLICK, _ -> {
                includeMoves = !includeMoves;
                box.setClass(StyleClass.FILTER_BOX_ON, includeMoves);
            });
            content.addComponent(option);

            var hint:Label = new Label();
            hint.percentWidth = 100;
            hint.text = LocaleUtils.localeBinding("intellector.games.export.moves_hint");
            hint.addClass(StyleClass.GAMES_EXPORT_HINT);
            content.addComponent(hint);

            var exportButton:ActionButton = new ActionButton(LocaleUtils.localeBinding("intellector.games.export.submit"), () -> {
                dismiss();
                onExport(includeMoves);
            }, true);
            return {
                regions: [
                    Header(LocaleUtils.localeBinding("intellector.games.export.title")),
                    Custom(BODY_HEIGHT, FilterDialogs.body(content)),
                    Actions(new ActionBar([new ActionButton(LocaleUtils.localeBinding("intellector.games.dialog.cancel"), dismiss), exportButton]))
                ]
            };
        }, null, FilterDialogs.geometry(BODY_HEIGHT));
    }

    /** `ID ↓, then White ↑` **/
    private static function sortText(sort:Array<SortLevel>):String
    {
        var parts:Array<String> = [
            for (level in sort)
                ArchiveFormatters.columnName(level.column) + " " + (level.descending ? "↓" : "↑")
        ];
        return parts.join(LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.export.then")) + " ");
    }

    private static function summaryRow(nameKey:String, value:Void->String):HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        var name:Label = new Label();
        name.percentWidth = 100;
        name.text = LocaleUtils.localeBinding(nameKey);
        name.addClass(StyleClass.GAMES_EXPORT_NAME);
        row.addComponent(name);
        var valueLabel:Label = new Label();
        LocaleManager.instance.registerComponent(valueLabel, "text", value);
        valueLabel.addClass(StyleClass.GAMES_EXPORT_VALUE);
        row.addComponent(valueLabel);
        return row;
    }
}
