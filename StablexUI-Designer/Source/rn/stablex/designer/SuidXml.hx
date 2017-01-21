package rn.stablex.designer;

import haxe.xml.Printer;

using StringTools;
using rn.typext.ext.XmlExtender;

class SuidXml {
	//-----------------------------------------------------------------------------------------------
	// additional xml-functions & workarounds for TextField
	
	public static function parseXml (xmlStr:String) : Xml
		return Xml.parse((~/^ +</gm).replace((~/^	+</gm).replace(xmlStr, "<"), "<").replace("\n", ""));
	
	public static function printXml (xml:Xml, indent:String) : String
		return Printer.print(xml, true).replace(">", ">\n").replace("	", indent).replace("   ", indent);
}
