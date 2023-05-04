package gfx.game.analysis.variation_tree.util;

import net.shared.variation.VariationPath;
import net.shared.variation.VariationMap;

class DisplacementInfo
{
    public var cellularMapping:VariationMap<Cell>;
    public var columnContents:Map<Int, Array<VariationPath>>;
    public var maxColumn:Int;

    public function addCell(path:VariationPath, row:Int, column:Int) 
    {
        cellularMapping.set(path, {row: row, column: column});

        if (columnContents.exists(column))
            columnContents[column].push(path);
        else
        {
            columnContents[column] = [path];
            if (maxColumn < column)
                maxColumn = column;
        }
    }

    public function new()
    {
        cellularMapping = new VariationMap(['' => {row: 0, column: 1}]);
        columnContents = [];
        maxColumn = 0;
    }
}