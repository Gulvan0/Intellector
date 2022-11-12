package gfx.profile.complex_components;

import dict.Dictionary;
import gfx.basic_components.utils.DimValue;
import net.shared.UserStatus;
import gfx.basic_components.AutosizingLabel;
import gfx.profile.simple_components.FriendListEntry;
import net.shared.FriendData;
import haxe.ui.containers.ScrollView;

class FriendList extends ScrollView
{
    private var noneLabel:AutosizingLabel;

    private function ordinalNumber(status:UserStatus):Int
    {
        return switch status {
            case Offline(secondsSinceLastAction): secondsSinceLastAction;
            case Online: -1;
            case InGame: -2;
        }
    }

    private function compare(x:FriendData, y:FriendData):Int 
    {
        return ordinalNumber(x.status) - ordinalNumber(y.status);
    }

    public function fill(friends:Array<FriendData>)
    {
        for (component in childComponents.slice(2))
            removeComponent(component);
        
        noneLabel.hidden = true;

        friends.sort(compare);

        for (data in friends)
            addComponent(new FriendListEntry(data));
    }

    public function new(w:DimValue, contentHeight:Float)
    {
        super();
        this.contentLayoutName = 'horizontal';
        this.contentHeight = contentHeight;
        assignWidth(this, w);
        
        var titleLabel:AutosizingLabel = new AutosizingLabel();
        titleLabel.text = Dictionary.getPhrase(PROFILE_FRIENDS_PREPENDER);
        titleLabel.customStyle = {fontBold: true};
        titleLabel.percentHeight = 100;
        addComponent(titleLabel);
        
        noneLabel = new AutosizingLabel();
        noneLabel.text = Dictionary.getPhrase(PROFILE_NO_FRIENDS_PLACEHOLDER);
        noneLabel.customStyle = {color: 0x999999, fontItalic: true};
        noneLabel.percentHeight = 100;
        addComponent(noneLabel);
    }
}