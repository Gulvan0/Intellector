package tests.unit;

import tests.ui.utils.FieldNaming;
import utest.Assert;
import tests.ui.FieldType;
import utest.Test;

class Testing extends Test
{
    private function testPrefixes() 
    {
        for (type in FieldType.createAll())
            Assert.same(type, FieldNaming.fieldTypeByPrefix(FieldNaming.fieldPrefixByType(type)));
    }
}