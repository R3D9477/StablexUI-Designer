package rn.stablex.designer;

typedef GuiDataInfo = {
	var guiUuid:String;
	var guiName:String;
	var parentGuiPath:String;
	var parentGuiAutoreg:Bool;
	
	var wgtSrcAct:Int;
	var project:String;
	var srcDir:String;
	
	var makeInstance:Bool;
	var guiInstanceTemplate:String;
	var guiInstancePath:String;
	var guiInstanceFunction:String;
	
	var preset:String;
	var embedAssets:Bool;
	
	var frameTemplate:String;
	var guiWidth:Float;
	var guiHeight:Float;
	var wndBackground:String;
	var wndFps:Int;
	var wndVsync:Bool;
	var wndBorderless:Bool;
	var wndResizable:Bool;
	var wndFullscreen:Bool;
	var wndHardware:Bool;
	var wndAllowShaders:Bool;
	var wndRequireShaders:Bool;
	var wndDepthBuffer:Bool;
	var wndStencilBuffer:Bool;
	var wndOrientation:String;
	
	var useGrid:Bool;
	var gridSize:Int;
	var gridType:Int;
	var gridColor:Int;
	var gridBorderSize:Int;
}
