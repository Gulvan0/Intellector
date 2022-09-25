package gfx.profile.complex_components;

import gfx.profile.data.UserStatus;
import gfx.basic_components.AutosizingLabel;
import gfx.profile.simple_components.FriendListEntry;
import gfx.profile.data.FriendData;
import haxe.ui.containers.ScrollView;

class FriendList extends ScrollView
{
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
        for (component in childComponents.slice(1))
            removeComponent(component);

        friends.sort(compare);

        for (data in friends)
            addComponent(new FriendListEntry(data));
    }

    public function new()
    {
        super();
        this.contentLayoutName = 'horizontal';
        
        var titleLabel:AutosizingLabel = new AutosizingLabel();
        titleLabel.text = "Friends: "; //TODO: Use dict
        titleLabel.customStyle = {fontBold: true};
        titleLabel.percentHeight = 100;
        addComponent(titleLabel);
    }
}