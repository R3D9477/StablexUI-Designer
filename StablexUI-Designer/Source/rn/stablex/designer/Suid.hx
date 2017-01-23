package rn.stablex.designer;

@:noCompletion class Suid {
	public static function getCurrSeconds () : Int // workaround for https://github.com/RealyUniqueName/StablexUI/issues/235
		return Date.now().getHours() * 60 * 60 + Date.now().getMinutes() * 60 + Date.now().getSeconds();
	
	public static function castType <T> (v:Dynamic, c:Class<T>) : T // needed for ViewStack
		return Std.is(v, c) ? cast v : null;
	
	public static function getCwd () : String
		return Suid.escPath(Sys.getCwd());
	
	public static function fullPath (path:String) : String
		return Suid.escPath(sys.FileSystem.fullPath(path));
	
	public static function escPath (path:String) : String // workaround for Windows
		return StringTools.replace(path, "\\", "/");
	
	public static function getSettings (guiName:String) : GuiDataInfo
		return System.guiSettings;
}
