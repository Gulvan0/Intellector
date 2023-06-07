package gfx.game.live;

import haxe.ui.events.UIEvent;
import haxe.ui.containers.VBox;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameScreenGetters;
import gfx.game.events.ModelUpdateEvent;
import haxe.ui.core.Component;
import gfx.game.interfaces.IGameComponent;
import gfx.game.events.SpecialControlSettingsEvent;
import gfx.utils.SpecialControlSettings;
import dict.Dictionary;
import dict.Phrase;
import gfx.utils.LMBArrowDrawingMode;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/live/special_control_settings_box.xml"))
class SpecialControlSettingsBox extends VBox implements IGameComponent
{
    private var getBehaviour:Void->IBehaviour;

    @:bind(fastPromotionSwitch, UIEvent.CHANGE)
    private function onFastPromotionSwitchChanged(e:UIEvent)
    {
        getBehaviour().handleSpecialControlSettingsEvent(SettingsUpdated(getSettings()));
    }

    @:bind(lmbArrowModeDropdown, UIEvent.CHANGE)
    private function onLmbArrowModeDropdownChanged(e:UIEvent)
    {
        getBehaviour().handleSpecialControlSettingsEvent(SettingsUpdated(getSettings()));
    }

    private function setFastPromotionSwitch(enabled:Bool)
    {
        var labelPhrase:Phrase = enabled? SETTINGS_ENABLED_OPTION_VALUE : SETTINGS_DISABLED_OPTION_VALUE;

        fastPromotionSwitch.selected = enabled;
        fastPromotionLabel.text = Dictionary.getPhrase(labelPhrase);
    }

    private function getSettings():SpecialControlSettings
    {
        return new SpecialControlSettings(fastPromotionSwitch.selected, LMBArrowDrawingMode.createByIndex(lmbArrowModeDropdown.selectedIndex));
    }

    private function initFromSettings(settings:SpecialControlSettings) 
    {
        setFastPromotionSwitch(settings.fastPromotion);

        lmbArrowModeDropdown.selectedIndex = settings.lmbArrowDrawingMode.getIndex();
    }

	public function init(model:ReadOnlyModel, getters:IGameScreenGetters) 
    {
        this.getBehaviour = getters.getBehaviour;

        for (arrowMode in LMBArrowDrawingMode.createAll())
            lmbArrowModeDropdown.dataSource.add(Dictionary.getPhrase(SPECIAL_CONTROL_SETTINGS_LMB_ARROW_MODE_SETTING_ITEM_TEXT(arrowMode)));

        initFromSettings(getters.getSpecialControlSettings());
    }

	public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent) 
    {
        //* Do nothing (doesn't react to anything)
    }

	public function destroy() 
    {
        //* Do nothing
    }

	public function asComponent():Component 
    {
		return this;
	}
}