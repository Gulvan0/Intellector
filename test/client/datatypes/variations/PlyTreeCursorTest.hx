package client.datatypes.variations;

import client.datatypes.variations.PlyTreeChange;
import intellectorboard.position.Position;
import testutils.Plies;
import utest.Assert;
import utest.Test;

class PlyTreeCursorTest extends Test
{
    private var changes:Array<PlyTreeChange>;

    private function cursor():PlyTreeCursor
    {
        changes = [];
        var cursor:PlyTreeCursor = new PlyTreeCursor(Position.defaultStarting());
        cursor.onChanged.subscribe(changes.push);
        return cursor;
    }

    private function playLegal(cursor:PlyTreeCursor, index:Int = 0):PlyTreeNode
    {
        cursor.play(Plies.legal(cursor.selected.position, index));
        return cursor.selected;
    }

    private function testStartsAtTheRoot():Void
    {
        var cursor:PlyTreeCursor = cursor();
        Assert.equals(cursor.tree.root, cursor.selected);
    }

    private function testPlayingANewPlySelectsItAsAStructuralChange():Void
    {
        var cursor:PlyTreeCursor = cursor();
        var node:PlyTreeNode = playLegal(cursor);

        Assert.equals(cursor.tree.root, node.parent);
        Assert.same([Structure], changes);
    }

    private function testPlayingAnExistingPlyOnlySelects():Void
    {
        var cursor:PlyTreeCursor = cursor();
        var node:PlyTreeNode = playLegal(cursor);
        cursor.select(cursor.tree.root);
        changes.resize(0);

        cursor.play(node.ply.copy());

        Assert.equals(node, cursor.selected);
        Assert.same([Selection], changes);
    }

    private function testPlayingFromAnInnerNodeAddsAVariation():Void
    {
        var cursor:PlyTreeCursor = cursor();
        var first:PlyTreeNode = playLegal(cursor, 0);
        playLegal(cursor);
        cursor.select(cursor.tree.root);

        var variation:PlyTreeNode = playLegal(cursor, 1);

        Assert.equals(2, cursor.tree.root.children.length);
        Assert.equals(first, cursor.tree.root.children[0]);
        Assert.equals(variation, cursor.tree.root.children[1]);
    }

    private function testSelectingTheSameNodeChangesNothing():Void
    {
        var cursor:PlyTreeCursor = cursor();
        cursor.select(cursor.tree.root);
        Assert.same([], changes);
    }

    private function testNavigatesAlongTheSelectedLine():Void
    {
        var cursor:PlyTreeCursor = cursor();
        var first:PlyTreeNode = playLegal(cursor);
        var second:PlyTreeNode = playLegal(cursor);
        var third:PlyTreeNode = playLegal(cursor);
        cursor.select(first);

        cursor.navigate(Next);
        Assert.equals(second, cursor.selected);
        cursor.navigate(End);
        Assert.equals(third, cursor.selected);
        cursor.navigate(Next);
        Assert.equals(third, cursor.selected);
        cursor.navigate(Previous);
        Assert.equals(second, cursor.selected);
        cursor.navigate(AfterPly(0));
        Assert.equals(first, cursor.selected);
        cursor.navigate(Start);
        Assert.equals(cursor.tree.root, cursor.selected);
        cursor.navigate(Previous);
        Assert.equals(cursor.tree.root, cursor.selected);
    }

    private function testNextFollowsTheFirstChild():Void
    {
        var cursor:PlyTreeCursor = cursor();
        var main:PlyTreeNode = playLegal(cursor, 0);
        cursor.select(cursor.tree.root);
        playLegal(cursor, 1);
        cursor.select(cursor.tree.root);

        cursor.navigate(Next);

        Assert.equals(main, cursor.selected);
    }

    private function testDeleteSelectsTheParent():Void
    {
        var cursor:PlyTreeCursor = cursor();
        var first:PlyTreeNode = playLegal(cursor);
        playLegal(cursor);
        cursor.select(first);
        changes.resize(0);

        cursor.deleteSelected();

        Assert.equals(cursor.tree.root, cursor.selected);
        Assert.equals(0, cursor.tree.moveCount());
        Assert.same([Structure], changes);
    }

    private function testRootIsNeverDeleted():Void
    {
        var cursor:PlyTreeCursor = cursor();
        playLegal(cursor);
        cursor.select(cursor.tree.root);
        changes.resize(0);

        cursor.deleteSelected();

        Assert.equals(1, cursor.tree.moveCount());
        Assert.same([], changes);
    }

    private function testResetStartsOver():Void
    {
        var cursor:PlyTreeCursor = cursor();
        playLegal(cursor);
        changes.resize(0);

        var position:Position = Position.defaultStarting().copy(Black);
        cursor.reset(position);

        Assert.equals(0, cursor.tree.moveCount());
        Assert.equals(cursor.tree.root, cursor.selected);
        Assert.equals(position, cursor.tree.root.position);
        Assert.same([Structure], changes);
    }
}
