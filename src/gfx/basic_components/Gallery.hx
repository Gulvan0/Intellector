package gfx.basic_components;

import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.HBox;

@:xml('
    <hbox>
        <style>
            .galleryBtn {
                pointer-events: true;
            }
            .galleryBtn:hover {
                background-color: 0xEEEEEE;
                background-opacity: 0.5;
            }
        </style>
        <image id="leftBtn" resource="assets/images/basic_components/gallery_left.svg" verticalAlign="center" width="10%" height="80%" styleName="galleryBtn" />
        <stack id="contentStack" width="80%" height="100%" />
        <image id="rightBtn" resource="assets/images/basic_components/gallery_right.svg" verticalAlign="center" width="10%" height="80%" styleName="galleryBtn" />
    </hbox>
')
class Gallery extends HBox
{
    @:bind(leftBtn, MouseEvent.CLICK)
    private function onLeftPressed(e) 
    {
        contentStack.prevPage();
    }

    @:bind(rightBtn, MouseEvent.CLICK)
    private function onRightPressed(e) 
    {
        contentStack.nextPage();
    }

    public function addPage(comp:Component)
    {
        contentStack.addComponent(comp);
    }
}