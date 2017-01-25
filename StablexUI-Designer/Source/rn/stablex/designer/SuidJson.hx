package rn.stablex.designer;

class SuidJson {
	//-----------------------------------------------------------------------------------------------
	// additional json-functions
	
	public static function encode (jsonStruct:Dynamic) : String
		return haxe.Json.stringify(jsonStruct);
	
	public static function parse (jsonStr:String) : Dynamic
		return haxe.Json.parse(jsonStr);
}
