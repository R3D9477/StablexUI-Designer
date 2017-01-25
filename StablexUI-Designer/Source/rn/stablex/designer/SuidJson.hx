package rn.stablex.designer;

class SuidJson {
	//-----------------------------------------------------------------------------------------------
	// additional json-functions
	
	public static function encode (jsonStruct:Dynamic) : String
		return tjson.TJSON.encode(jsonStruct);
		//return haxe.Json.stringify(jsonStruct);
		//return haxe.format.JsonParser.parse(jsonStruct);
	
	public static function parse (jsonStr:String) : Dynamic
		return tjson.TJSON.parse(jsonStr);
		//return haxe.Json.parse(jsonStr);
		//return haxe.format.JsonPrinter.print(jsonStr);
}
