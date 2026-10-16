package client.formatters;

import utest.Assert;
import utest.Test;

class PluralsTest extends Test
{
    private function testEnglish():Void
    {
        Assert.equals("one", Plurals.form(1, "en"));
        for (count in [0, 2, 5, 11, 21, 101])
            Assert.equals("many", Plurals.form(count, "en"));
    }

    private function testRussian():Void
    {
        for (count in [1, 21, 101, 1001])
            Assert.equals("one", Plurals.form(count, "ru"));
        for (count in [2, 3, 4, 22, 34, 102])
            Assert.equals("few", Plurals.form(count, "ru"));
        for (count in [0, 5, 11, 12, 13, 14, 15, 20, 111, 112, 114])
            Assert.equals("many", Plurals.form(count, "ru"));
    }

    private function testKey():Void
    {
        Assert.equals("intellector.analysis.moves.few", Plurals.key("intellector.analysis.moves", 3, "ru"));
        Assert.equals("intellector.analysis.moves.many", Plurals.key("intellector.analysis.moves", 3, "en"));
    }
}
