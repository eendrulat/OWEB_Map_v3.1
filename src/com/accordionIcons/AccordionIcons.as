package com.accordionIcons
{
	import mx.containers.Accordion;
	import mx.core.Container;
	import flash.events.Event;
	

	/**
	 *  <p>The AccordionIcons component extends Accordion and 
	 *  allows for icons to be assigned to each pane</p>
	 *
	 *  <p>The icons will be automatically assigned to the appropriate pane each time
	 *  the state of the Accordion changes.</p>
	 *
	 *  @mxml
	 *
	 * <pre>
	 *  &lt;flexlib:AccordionIcons
	 * 	  <strong>Properties</strong>
	 *    &gt;
	 *    ...
	 *      <i>child containers (Canvas, VBox, HBox, etc.)</i>
	 *    ...
	 *  &lt;/flexlib:AccordionIcons&gt;
	 *  </pre>
	 * 
	 *  <pre>
	 *  &lt;flexlib:AccordionIcons
	 * 	  <strong>Properties</strong>
	 * 	  upIcon="@Embed(source='yourUpIcon.png')"
	 * 	  downIcon="@Embed(source='yourDownIcon.png')"
	 * 	  selectedIcon="@Embed(source='yourSelectedIcon.png')"
	 *    &gt;
	 *    ...
	 *      <i>child containers (Canvas, VBox, HBox, etc.)</i>
	 *    ...
	 *  &lt;/flexlib:AccordionIcons&gt;
	 *  </pre>
	 */

	public class AccordionIcons extends Accordion
	{
		/**
	 	* Property that holds the icon Class that will show when 
	 	* the Accordion pane is above the selected pane
	 	* 
	 	* formats: gif,png,jpg 
	 	* 
	 	* @default upIcon.gif
	 	*/	
	 	[Embed(source="upIcon.gif")] 
        [Bindable]
        public var upIcon:Class;
        
        /**
	 	* Property that holds the icon Class that will show when 
	 	* the Accordion pane is below the selected pane
	 	* 
	 	* formats: gif,png,jpg 
	 	* 
	 	* @default rightIcon.gif
	 	*/	
	 	[Embed(source="rightIcon.gif")] 
        [Bindable]
        public var rightIcon:Class;
        
        /**
	 	* Property that holds the icon Class that will show when 
	 	* the Accordion pane is the selected pane
	 	* 
	 	* formats: gif,png,jpg 
	 	* 
	 	* @default selectedIcon.gif
	 	*/	
	 	[Embed(source="selectedIcon.gif")] 
        [Bindable]
        public var selectedIcon:Class;
        
        /**
	 	 *  @private
	 	 */	
		private var defaultWidth:int = 400;
        
        /**
	 	 *  @private
	 	 */	
		private var defaultHeight:int = 300;
        
        /**
		 * Constructor
		 * Initialize a default witdth of 400 and default height of 300
		 */
        public function AccordionIcons(){
        	super();
        	// set defaultWidth and defaultHeight
        	this.width = this.defaultWidth;
        	this.height = this.defaultHeight;
        } 
        
        /**
		 * The childrenCreated method is overridden to initialize the icons
		 * and add the CHANGE EventListener.
		 */
        override protected function childrenCreated():void{
        	setIcons(this.selectedIndex);
        	this.addEventListener(Event.CHANGE,changed);
        }
        
        /**
         * @private 
         * 
		 * The changed function is called when the Accordion changes state
		 */
        private function changed(event:Event):void{
        	setIcons(event.target.selectedIndex);
        }
        
        /**
         * @private 
         * 
		 * Assigns each pane the with either the upIcon, downIcon, or selectedIcon
		 */
        private function setIcons(selectedIndex:int):void{
        	for(var i:int=0; i<this.numChildren; i++){
        		if(i>=selectedIndex){
        			// if pane is above selectedIndex, set with upIcon
        			Container(this.getChildAt(i)).icon = upIcon;
        		} else {
        			// if pane is above selectedIndex, set with downIcon
        			Container(this.getChildAt(i)).icon = rightIcon;
        		}
        	}
        	// set the selectedIcon to the selected pane
        	Container(this.getChildAt(selectedIndex)).icon = selectedIcon;
        }
		
	}
}