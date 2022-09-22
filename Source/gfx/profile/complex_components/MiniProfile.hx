package gfx.profile.complex_components;

import gfx.profile.simple_components.TCEloEntry;
import gfx.profile.data.EloData;
import net.shared.EloValue;
import utils.AssetManager;
import gfx.basic_components.AnnotatedImage;
import net.shared.TimeControlType;
import haxe.ds.BalancedTree;
import dict.Dictionary;
import gfx.profile.simple_components.PlayerLabel;
import gfx.profile.data.MiniProfileData;
import gfx.profile.Utils;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.Screen as HaxeUIScreen;

@:xml('
    <dialog title="" >
        <vbox id="contentsBox" width="100%">
            <label id="usernameLabel" />
            <label id="statusLabel" />
            <hbox id="elosBox" continuous="true" width="100%" />
            <buttonbar id="btnBar" horizontalAlign="right" />
        </vbox>
    </dialog>
')
class MiniProfile extends Dialog
{
    private function resize()
    {
        width = Math.min(400, HaxeUIScreen.instance.actualWidth * 0.98);
    }

    public function onClose(?e)
    {
        SceneManager.removeResizeHandler(resize);
    }

    private function eloOrdinalNumber(gamesCnt:Int, tc:TimeControlType):Float
    {
        return gamesCnt + 0.1 * tc.getIndex();
    }

    public function new(username:String, data:MiniProfileData, enableActions:Bool)
    {
        super();

        usernameLabel.text = username;
        Utils.updateStatusLabel(statusLabel, data.status);

        var tree:BalancedTree<Float, EloData> = new BalancedTree();
           
        for (tc => gamesCnt in data.gamesCntByTimeControl.keyValueIterator())
        {
            var key:Float = eloOrdinalNumber(gamesCnt, tc);
            var data:EloData = {timeControl: tc, elo: data.elo.get(tc)};
            tree.set(key, data);
        }

        for (data in tree)
            elosBox.addComponent(new TCEloEntry(data));

        //TODO: Add buttons to btnBar
        //TODO: Specify dialog title
    }
}