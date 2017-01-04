package rn.stablex.designer;

/*import openfl.events.*;
import openfl.net.FileFilter;
import openfl.net.FileReference;*/

class Dialogs {
	public static function openFile (title:String, desc:String, defaultDir:String, descriptions:Array<String>, extensions:Array<String>, onSelect:String->Void) : Void {
		var oFiles:Array<String> = systools.Dialogs.openFile(title, desc, { count: 1,  descriptions: descriptions, extensions: extensions });
		onSelect(oFiles == null ? oFiles[0] : null);
		
		//var loadRef:FileReference = new FileReference();
		//loadRef.browse([for (i in 0...descriptions.length) new FileFilter(descriptions[i], extensions[i])]);
		
		//loadRef.addEventListener(Event.SELECT, function(e:Event) cast(e.target, FileReference).load());
		//loadRef.addEventListener(Event.COMPLETE, function(e:Event) onSelect(e.target.data));
	}
	
	public static function saveFile (title:String, desc:String, defaultDir:String, descriptions:Array<String>, extensions:Array<String>, onSelect:String->Void) : Void {
		onSelect(systools.Dialogs.saveFile(title, desc, defaultDir, { count: 1,  descriptions: ["XML files"], extensions: ["*.xml"] }));
	}
	
	public static function openFolder (title:String, desc:String, defaultDir:String, onSelect:String->Void) : Void
		onSelect(systools.Dialogs.folder(title, desc));
	
	public static function showMessage (message:String, isError:Bool) : Void
		systools.Dialogs.message("neko-systools", message, isError);
}
