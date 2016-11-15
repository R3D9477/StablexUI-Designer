/*
The MIT License (MIT)

Copyright (c) 2014 Tony DiPerna

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/**
 * Custom stablexui vertical grid widget.  
 * Wraps the usual scroll widget and allows us to add an infinite
 * amount of items while scrolling vertically to accomodate them.  
 * 
 * Website    : http://www.xenizogames.com
 * Repository : https://github.com/XenizoGames/blog_stablexui_gridwidget
 * Blog Post  : http://www.xenizogames.com/blog/
 * @author Tony DiPerna (Xenizo Games)
 */

package;

import openfl.display.*;

import ru.stablex.ui.*;
import ru.stablex.ui.skins.*;
import ru.stablex.ui.events.*;
import ru.stablex.ui.widgets.*;
import ru.stablex.ui.layouts.*;

import motion.Actuate;

class GridWidget extends Scroll {
	//container that holds all columns and will be scrolled
	public var gridList:ru.stablex.ui.widgets.HBox;
	
	//The data grid columns
	public var columns:Array<ru.stablex.ui.widgets.VBox>;
	
	//total cols in this grid
	private var _numCols:Int;
	//total rows in this grid
	private var _numRows:Int;
	//Current column index, this is used so we know where to add the next grid item
	private var _currIndex:Int;
	
	//The width of a single list item in px
	private var itemWidth:Int;
	//Height of a list item in px
	private var itemHeight:Int;
	
	//The total height of the scrollable area 
	//(usually much larger than viewable area)
	private var _scrollHeight:Float;
	
	public function new() : Void {
		super();
		
		//init internal variables
		this._currIndex = 0;
		this._numRows = 0;
		
		//This is the grid of items itself which will be scrolled
		//Its a horizontal box that will have a number of columns inside
		this.gridList = new HBox();
		this.gridList.widthPt = 100;
		this.gridList.heightPt = 100;
		
		this.itemWidth = 1;
		this.itemHeight = 1;
		
		super.addEventListener(WidgetEvent.RESIZE, function (e:WidgetEvent) {
			//Calc num of columns, columns autosize depending on viewable size
			this._numCols = Math.floor(this.w / this.itemWidth);
			
			//Set scrollable size for this widget
			//This is a gridwidget that scrolls vertically, so width must match viewable width
			//Store this here since it will change as we add more widgets
			this._scrollHeight = this.h;
		});
		
		this.dispatchEvent(new WidgetEvent(WidgetEvent.RESIZE));
		
		//Listeners that allow us to change scrollbar behavior
		super.addEventListener(WidgetEvent.SCROLL_START, onScrollStart);
		super.addEventListener(WidgetEvent.SCROLL_STOP, onScrollStop);
		
		//Add the grid to the scroll container, this makes it the item 
		//that will be scrolled for stablexui (first child)
		super.addChild(this.gridList);
		
		//Setup columns in the grid
		this.gridSetup();
		
		//redraw/organize the grid, needed after any change in the grid
		this.refresh();
		
		//fade out the scrollbar
		Actuate.tween(this.vBar, 2.0, { alpha: 0 });
	}
	
	private function onScrollStart (e:WidgetEvent):Void {
		//fade in vertical scrollbar
		Actuate.stop(this.vBar);
		Actuate.tween(this.vBar, 1.0, { alpha: 1 });
	}
	
	private function onScrollStop (e:WidgetEvent):Void {
		//fade out the scrollbar
		Actuate.stop(this.vBar);
		Actuate.tween(this.vBar, 1.0, { alpha: 0 });
	}
	
	private function gridSetup () : Void {
		//columns needed by stableXUI
		var cols = this.getColumnArrayForGrid(this._numCols); 
		
		//Dynamically create columns that fit width of screen
		var columnLayout = new Column();
		columnLayout.cols = cols;
		
		this.gridList.layout = columnLayout;
		this.gridList.applyLayout();
		
		this.columns = new Array<VBox>();
		
		//add a widget for each column and store columns
		for (n in 0...this._numCols)
		{
			var b = new VBox();
			b.childPadding = 5;
			b.name = "col" + Std.string(n + 1);
			//must be top or else when removing/adding to the columns height gets messed up
			b.align = "center,top"; 
			this.gridList.addChild(b);
			this.columns.push(b);
		}
	}
	
	public function addToEndOfGrid(inWidget:Widget):Void {
		super.addChild(inWidget);
		this.resortGrid();
	}
	
	public function addToStartOfGrid(inWidget:Widget):Void {
		//add to start of grid then resort to look nice
		this.columns[0].addChildAt(inWidget, 1);
		this.resortGrid();
	}
	
	public function addToMiddleOfGrid (inWidget:Widget) : Void {
		//add item to middle (approx.) of grid then resort to look nice
		var firstCol = this.columns[0];
		//approx. half way down first col
		var insertPos = this.getApproxMiddleRow(firstCol.numChildren);
		//add to mid
		this.columns[0].addChildAt(inWidget, insertPos);
		this.resortGrid();
	}
	
	public function removeWidget (inWidget:Widget) : Void {
		//Error Checking
		if (inWidget == null)
			throw("Error: null parameter, please verify widget for removal");
		
		//Make sure we actually have this widget in the grid, 
		//if we don't then don't do anything
		if (inWidget.parent != this.gridList)
			throw("Error: trying to remove a widget that doesn't belong to this grid, real parent is: " + inWidget.parent);
		
		//remove the item from the list
		inWidget.parent.removeChild(inWidget);
		this.resortGrid();
	}
	
	override public function addChild (inWidget:DisplayObject) : DisplayObject {
		//Add to the next column
		this.columns[this._currIndex].addChild(inWidget);
		
		//increment so next add goes to next column
		this._currIndex++;
		
		//make sure we roll back to first column when exceeding num cols
		if (this._currIndex >= this._numCols) {
			this._currIndex = 0;
			this._numRows++;
		}
		
		return inWidget;
	}
	
	override public function refresh () : Void {
		//make sure we don't have any half complete rows.
		//if we do refresh the total scrollable height
		//to make sure we can see all rows (even uncomplete ones)
		this.checkForUnfinishedRows();
		
		//Set the height of the list based on the number of rows we have, 
		//we need this calculation to make the scrollable area fits the num of rows 
		//(that can change dynamically), without this the scrollable area is "off" 
		//and doesnt work very cleanly
		//
		//+1 since arrays are 0 based, but viewable display is 1 based (need to see first row)
		this.gridList.h = this.getScrollHeight(this._numRows + 1, this.itemHeight);
		
		//Refresh each column individually to make sure layout is clean
		for (c in columns)
			c.refresh();
		
		//stablexui widget refresh behavior
		super.refresh();
	}
	
	private inline function getApproxMiddleRow (inNumRows:Int) : Int {
		return inNumRows > 0 ? Math.floor(inNumRows / 2) : 0;
	}
	
	private inline function checkForUnfinishedRows () : Void {
		//one more row to make sure we have enough to see everything
		//this is needed since we started a new row but didnt finish it
		//When currIndex > 0 it means the next free column is NOT the first column
		if (this._currIndex > 0) {
			this._numRows++;
		}
	}
	
	private function resortGrid () : Void {
		//Create flat array as temporary storage doing resort
		var items = new Array<DisplayObject>();
		var totalChildren = 0;
		
		//find column with most stuff in it...we need to check this because
		//items can be added/removed from the grid
		for (c in columns)
			if (totalChildren < c.numChildren)
				totalChildren = c.numChildren;
		
		//loop through all columns and get the lowest index child (at the top in y-dir) 
		//to preserve current order of grid items.  We basically build a flat array from 
		//each columns list of children to maintain order, then re-sort the flat array
		//and break back into columns
		for (z in 0...totalChildren)
			for (col in columns)
				if (col.numChildren > 0)
				{
					//get the item currently at the top of the column
					var item:DisplayObject = col.getChildAt(0);
					
					//Make sure we are not grabbing some kind of background object
					if (Std.is(item, Widget))
					{
						//found an item - store it an the flat array
						items.push(item);
						
						//remove item from its old column
						item.parent.removeChild(item);
					}
				}
		
		//Reset internal class variables since we are resorting
		this._currIndex = 0;
		this._numRows = 0;
		
		//Add all items back to the columns from the flat array
		for (i in items) {
			this.columns[_currIndex].addChild(i);
			
			this._currIndex++;
			
			//roll back to first column
			if (this._currIndex >= this._numCols) {
				this._currIndex = 0;
				this._numRows++;
			}
		}
		
		//redraw the grid and all child widgets
		this.refresh();
	}
	
	private inline function getScrollHeight (inNumRows:Int, inHeight:Int) : Int {
		//guard for min condition (only 1 row)
		return Math.floor(Math.max(inNumRows * inHeight, this._scrollHeight));
	}
	
	private function getColumnArrayForGrid (inNumCols:Int) : Array<Float> {
		//Verify parameters
		if (inNumCols <= 1)
			throw("Error: invalid number of columns, need at least 2 columns for a valid grid layout");
		
		var cols = new Array<Float>();
		var perc = 1 / inNumCols; //Even percent for columns
		
		//add a new array entry for each column
		for (i in 0...inNumCols)
			cols.push(perc);
		
		return cols;
	}
}
