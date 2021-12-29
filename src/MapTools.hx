class MapTools {
	public static function count<K,V>(map : Map<K,V>) : Int {
		var c = 0;
		for (_ in map.keys()) c += 1;
		return c;
	}

	public static function isEmpty<K,V>(map : Map<K,V>) : Bool {
		return count(map) == 0;
	}
}
