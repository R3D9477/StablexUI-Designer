/*
	WARNING!
	This file was autogenerated by StablexUI-Designer.
	
	Don't change it manually, because it's can do unstable the work of StablexUI-Designer
		and can damage your project.
*/

package %InstancePackage%;

@:noCompletion class ClockTime { // workaround for https://github.com/RealyUniqueName/StablexUI/issues/235
	public static function getCurrSeconds () : Int
		return Date.now().getHours() * 60 * 60 + Date.now().getMinutes() * 60 + Date.now().getSeconds();
}

@:noCompletion class TypeCast { // needed for ViewStack
	public static function castType <T> (v:Dynamic, c:Class<T>) : T
		return Std.is(v, c) ? cast v : null;
}

class %InstanceName% {
	@:noCompletion macro public static function geInit () : Void // create source of GuiElements class
	
	#if !macro
	// fields of instances
	
	public static function load () {
		ru.stablex.ui.UIBuilder.regClass("haxe.io.Path");
		ru.stablex.ui.UIBuilder.regClass("openfl.display.BitmapData");
		ru.stablex.ui.UIBuilder.regClass("ru.stablex.ui.skins.Skin");
		ru.stablex.ui.UIBuilder.regClass("%InstancePackageDot%ClockTime");
		ru.stablex.ui.UIBuilder.regClass("%InstancePackageDot%TypeCast");
		
		// UIBuilder initialization
		
		// skins registration
		
		// initialization of instances
	}
	#end
}
