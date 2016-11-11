package rn.stablex.designer;

typedef GuiDataInfo = {
	var guiUuid:String;
	var guiName:String;
	
	var wgtSrcAct:Int;
	var project:String;
	var srcDir:String;
	
	var makeInstance:Bool;
	var guiInstanceTemplate:String;
	var guiInstancePath:String;
	var rootName:String;
	
	var preset:String;
	
	var frameTemplate:String;
	var guiWidth:Float;
	var guiHeight:Float;
	var fixedWindowSize:Bool;
}
