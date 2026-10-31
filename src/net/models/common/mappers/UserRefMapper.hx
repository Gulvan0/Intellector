package net.models.common.mappers;

import client.formatters.UserRefFormatters;

class UserRefMapper
{
    /** The name to show for `dto`, see `UserRefFormatters.displayName` **/
    public static function displayName(dto:UserRefWithNickname):String
    {
        return UserRefFormatters.displayName(dto.user_ref, dto.nickname);
    }
}
