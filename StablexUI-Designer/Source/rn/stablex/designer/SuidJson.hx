package rn.stablex.designer;

class SuidJson {
	//-----------------------------------------------------------------------------------------------
	// additional json-functions
	
	public static function encode (jsonStruct:Dynamic) : String
		return tjson.TJSON.encode(jsonStruct);
	
	public static function parse (jsonStr:String) : Dynamic
		return tjson.TJSON.parse(jsonStr);
}
