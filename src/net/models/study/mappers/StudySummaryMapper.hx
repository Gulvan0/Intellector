package net.models.study.mappers;

import client.datatypes.study.StudySummary;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;

class StudySummaryMapper
{
    public static function dtoToDatatype(dto:StudySummaryPublic):StudySummary
    {
        var keyPosition:Position = new Sip(dto.key_sip).toPosition() ?? Position.defaultStarting();
        return new StudySummary(dto.id, dto.name, dto.description, [for (tag in dto.tags) tag.tag], keyPosition);
    }
}
