package lib.std.extensions;

class MapExtension
{
	public static function mergeWith<K, V>(map1:Map<K, V>, map2:Map<K, V>, prioritizeOriginal:Bool = false):Map<K, V>
	{
		var result = map1.copy();
		for (key => value in map2)
			if (!prioritizeOriginal || !result.exists(key))
				result.set(key, value);
		return result;
	}
}
