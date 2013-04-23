// ActionScript file
import com.esri.ags.FeatureSet;
import com.esri.ags.Graphic;
import com.esri.ags.components.supportClasses.InfoWindow;
import com.esri.ags.events.ExtentEvent;
import com.esri.ags.events.MapMouseEvent;
import com.esri.ags.events.QueryEvent;
import com.esri.ags.geometry.Extent;
import com.esri.ags.geometry.Geometry;
import com.esri.ags.geometry.MapPoint;
import com.esri.ags.geometry.Polygon;
import com.esri.ags.layers.GraphicsLayer;
import com.esri.ags.portal.supportClasses.PopUpInfo;
import com.esri.ags.tasks.supportClasses.AddressCandidate;
import com.esri.ags.tasks.supportClasses.AddressToLocationsParameters;
import com.esri.ags.tools.NavigationTool;
import com.ext.InfoWindowRollOverContent;

import flash.events.Event;
import flash.events.MouseEvent;

import mx.collections.ArrayCollection;
import mx.collections.IViewCursor;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.controls.Alert;
import mx.controls.DataGrid;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.effects.Glow;
import mx.events.ItemClickEvent;
import mx.events.ListEvent;
import mx.formatters.DateFormatter;
import mx.rpc.AsyncResponder;

private var _data:Object;
private var _graLyr:GraphicsLayer;
private var _resultsGrid:DataGrid;
private var highlightedGraphic:Graphic;
private var _zoomScale:Number = 5000;
//private var _bWidget:BaseWidget;
private var _dgColumns:String="";
private var _dgHyperColumns:String="";
private var _bHyperAlias:Boolean=false;
private var _csvName:String;
private var _dgAliases:Object;
//end variables to support exportable data grid

[Bindable] private var countyName:String;
[Bindable] private var sdName:String;
[Bindable] private var hdName:String;
[Bindable] private var wsName:String;
[Bindable] private var layerWatershedFundingVis:String;
[Bindable] private var lastIdentifyResultGraphic:Graphic;

[Bindable]
[Embed(source="oitt_images/BaseMap_Aerial.jpg")]
public var imagery:Class;
 
[Bindable]
[Embed(source="oitt_images/BaseMap_Road.jpg")]
public var streetmap:Class;
 
[Bindable]
[Embed(source="oitt_images/BaseMap_Topo.jpg")]
public var topo:Class;		

private const content:InfoWindowRollOverContent = new InfoWindowRollOverContent;

[Bindable] private var currentScale:Number;             
private var queryParams:String;
private var unionExtent:Extent;  //county extent
private var unionExtentHUC:Extent; //huc extent
private var unionExtentSD:Extent; //SD extent
private var unionExtentHD:Extent; //HD extent
private var currentGraphicLayer:GraphicsLayer; // symbolize graphics according to checkboxes
[Bindable] private var layerProjAwardDyn_Vis:Boolean;
[Bindable] private var layerProjTypeDyn_Vis:Boolean;

private var fullExtent:Extent;  //full map extent

//triggered while map is initializing
private function init(e:Event):void 
{
    fullExtent = map.extent;
    //setup paremeters for infoWindow
	map.infoWindow.content = content;
	//map.infoWindowContent = content;
	map.infoWindow.labelVisible = false;
	map.infoWindow.closeButtonVisible = true;
}

//triggered when map is done intializing
private function doneInit(e:Event):void
{
   	chk_LyrWatershedBounds.selected = true;
    layerProjTypeDyn_Vis = true;
	//chk_LyrProjType.selected = true;
    map.addEventListener(MapMouseEvent.MAP_CLICK, onHUCClick);
   	NotificationText.text = "Tip: Click on the map to view projects within a selected watershed";
}  

//set up functions to allow zooming and filtering by counties
private function onMapClick(event:MapMouseEvent):void
{
	if (chk_LyrProjAward.selected || chk_LyrProjType.selected)
	{}
	else
	{
		chk_LyrProjType.selected = true;
	}
	
	if (map.scale > 99000)
	{
		queryCounty.geometry = event.mapPoint;
		queryCounty.where = "";
		queryTaskCounties.execute(queryCounty);
	}
	else{}
}


//set up functions to allow zooming and filtering by HUC
private function onHUCClick(event:MapMouseEvent):void
{
	if (chk_LyrProjAward.selected || chk_LyrProjType.selected)
	{}
	else
	{
		chk_LyrProjType.selected = true;
	}
	
	if (map.scale > 99000)
	{
		queryHUC.geometry = event.mapPoint;
		queryHUC.where = "";
		queryTaskHUC4.execute(queryHUC);
	}
	else{}
}

//set up functions to allow zooming and filtering by HUC
private function onSDClick(event:MapMouseEvent):void
{
	if (chk_LyrProjAward.selected || chk_LyrProjType.selected)
	{}
	else
	{
		chk_LyrProjType.selected = true;
	}
	
	if (map.scale > 99000)
	{
		querySD.geometry = event.mapPoint;
		querySD.where = "";
		queryTaskSD.execute(querySD);
	}
	else{}
}

//set up functions to allow zooming and filtering by HUC
private function onHDClick(event:MapMouseEvent):void
{
	if (chk_LyrProjAward.selected || chk_LyrProjType.selected)
	{}
	else
	{
		chk_LyrProjType.selected = true;
	}
	
	if (map.scale > 99000)
	{
		queryHD.geometry = event.mapPoint;
		queryHD.where = "";
		queryTaskHD.execute(queryHD);
	}
	else{}
}

//Handle Extent change event: deactivate toolbar
private function onExtentChange(event:ExtentEvent):void
{
	currentScale = map.scale;

	if (fText) //check if text search box is initialized
	{
		if (fText.text.length >0) // if so; then check if it is populated
		{
			if (chk_LyrProjType.selected || chk_LyrProjAward.selected) // if the Project type or Project Award layers are turned on; then run project query & turn off dynamic layers
			{
				doProjectQuery();
				layerProjAwardDyn_Vis = false;
				layerProjTypeDyn_Vis = false;
			}	
		}
	}
	
	if (currentScale < 3000000 || fText.text.length > 0) // check if the scale is < 1:3M OR  the search text box isn't populated
	{
			notificationBox.visible = false;
			if (chk_LyrProjType.selected || chk_LyrProjAward.selected) // check if the Project type or Project Award layers are turned on; then run project query & turn off dynamic layers
			{
				doProjectQuery();
				layerProjAwardDyn_Vis = false;
				layerProjTypeDyn_Vis = false;
				currentGraphicLayer.visible=true;
			}
			else {return;}	
	}
	else  // scale > 1:3M
	{
		if (currentGraphicLayer) // check if project graphics layer is initiallized
		{
			currentGraphicLayer.visible=false;
		}

		if (chk_LyrProjAward.selected) // if Project Award checkbox is selected, turn on 
		{
			layerProjAwardDyn_Vis = true;
			layerProjTypeDyn_Vis = false;
		}
		if (chk_LyrProjType.selected)
		{
			layerProjTypeDyn_Vis = true;
			layerProjAwardDyn_Vis = false;
		}
		
		info.text= "";
	}
	
	tbb.selectedIndex = -1;
	
}


//process navigation toolbar events 
private function itemClickHandler(event:ItemClickEvent):void
{
	switch (event.index)
	{
		case 0:
		{
			navTool.activate(NavigationTool.ZOOM_IN);
			break;
		}
		case 1:
		{
			navTool.activate(NavigationTool.ZOOM_OUT);
			break;
		}
		case 2:
		{
			navTool.activate(NavigationTool.PAN);
			break;
		}
	}     
}         

//set up query task for Projects
private function doProjectQuery():void
{
	if (chk_LyrProjType.selected)
 	{
 		currentGraphicLayer = layerProjType;
 		layerProjTypeDyn_Vis = true;
 		layerProjAwardDyn_Vis = false;
 		
 	}
 	else if (chk_LyrProjAward.selected)
 	{
 		currentGraphicLayer = layerProjAward;
 		layerProjAwardDyn_Vis = true;
 		layerProjTypeDyn_Vis = false;	
 	}
	queryProjects.geometry = map.extent;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
}

private function zoomFull():void
{
   	map.extent = fullExtent.expand(1);	
	dg.dataProvider.removeAll();
	countyBounds.clear();
	hucBounds.clear();
	sdBounds.clear();
	hdBounds.clear();
	info.text = "";
}

private function updateYearFilter():void
{
	if (chk_FilterYear.selected)
	{
		queryParams = "YearStart =" + sliderYear.value;
		//layerProjAwardDyn_Vis = false;
		//layerProjTypeDyn_Vis = false;
	}
	else
	{
		queryParams = "1=1";
	}
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
}

// search records based on text input into search panel //
// filter by Grant Type
private function doFindProjType():void
{
	if (chk_project.selected)  //don't bother to filter anything if filter isn't active
	{
		if (chk_county.selected)  //check if county filter is active, if so, append the grant typ filter to it
		{
			queryParams = "ProjectType = '" + dd_ProjectType.text+"'" + " AND County= '" + dd_County.text+"'";
		}
		else
		{
			queryParams = "ProjectType = '" + dd_ProjectType.text+"'";
		}
	}
	else  //filter for county, if applicable, otherwise clear filter
	{
			if (chk_county.selected)
			{
				queryParams = "County= '" + dd_County.text+"'";
			}
			else
			{
				queryParams = "1=1";
			}			
	}
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
	if (currentGraphicLayer)
	{
		currentGraphicLayer.refresh();	
	}
}

//filter by county
private function filterByCounty():void
{
	if (chk_county.selected)  //don't bother to filter anything if filter isn't active
	{
		map.addEventListener(MapMouseEvent.MAP_CLICK, onMapClick);
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onHUCClick);
		hucBounds.clear();
		sdBounds.clear();
		hdBounds.clear();
		
		if (dd_County.text=="All")  //as default, all counties are selected from dropdown
		{
			if (chk_project.selected)
			{
				queryParams = "ProjectType = '" + dd_ProjectType.text+"'";			
			}
			else
			{
				queryParams = "1=1";
			}				
		}
		else
		{		
			if (chk_project.selected)
			{
				queryParams = "ProjectType = '" + dd_ProjectType.text+"'" + "AND County= '" + dd_County.text+"'";			
				//queryCounty.where = "ProjectType = '" + dd_ProjectType.text+"'" + "AND County= '" + dd_County.text+"'";
				//queryCounties.execute(queryCounty);	
			}
			else
			{
				queryParams = "County= '" + dd_County.text+"'";
				//Alert.show(dd_County.text);
        		queryCounty.where = "NAME= '" + dd_County.text+"'";
				queryCounty.geometry = fullExtent;
				queryTaskCounties.execute(queryCounty);			
			}
		}		
	}		
	else  //filter for project type, if applicable, otherwise clear filter
	{
		if (chk_project.selected)
		{
			queryParams = "ProjectType = '" + dd_ProjectType.text+"'";			
		}
		else
		{
			queryParams = "1=1"
		}
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onMapClick);
		if (GraphicsLayer(currentGraphicLayer))
		{
			GraphicsLayer(currentGraphicLayer).clear();	
		}
	}
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
	
	if (currentGraphicLayer)
	{
		currentGraphicLayer.refresh();	
	}
}

//handle event passed from HUC Filter
private function filterByHUC():void
{
	if (chk_Watershed.selected)
	{
		map.addEventListener(MapMouseEvent.MAP_CLICK, onHUCClick);
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onMapClick);
		countyBounds.clear();

	}
	else
	{
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onHUCClick);
		hucBounds.clear();
	}
}

private function onHUCQueryResult(event:QueryEvent) : void
{
    var fset:FeatureSet = event.featureSet;       
	var myFirstGraphic:Graphic = fset.features[0];
   	
   	if (myFirstGraphic)
   	{
   		unionExtentHUC = Polygon(myFirstGraphic.geometry).extent;	
   	}
   	else {return;}
    
    for each (var myGraphic1:Graphic in fset.features)
    {
    	if (wsName == myGraphic1.attributes.HU_8_NAME)
  		{return;}
		else
		{
			hucBounds.clear();
			unionExtentHUC = unionExtentHUC.union(Polygon(myGraphic1.geometry).extent);
	        myGraphic1.symbol = clickSymbol;
	   		hucBounds.add(myGraphic1);
	   		wsName = myGraphic1.attributes.HU_8_NAME;
   		}   	
    }
	map.extent = unionExtentHUC.expand(1.3);
	queryParams = "Watershed= '" + wsName+"'";
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
}

private function countyQueryComplete(event:QueryEvent):void
{
    var fset:FeatureSet = event.featureSet;       
	var myFirstGraphic:Graphic = fset.features[0];
	
	if (myFirstGraphic)
   	{
   		unionExtent = Polygon(myFirstGraphic.geometry).extent;
   	}
   	else {return;}
   	
    for each (var myGraphic1:Graphic in fset.features)
    {
    	if (countyName == myGraphic1.attributes.NAME)
  		{}
		else
		{
			countyBounds.clear();
			unionExtent = unionExtent.union(Polygon(myGraphic1.geometry).extent);
	        myGraphic1.symbol = clickSymbol;
	   		countyBounds.add(myGraphic1);
	   		countyName= myGraphic1.attributes.NAME;
   		}
    }
	dd_County.text = countyName;
	map.extent = unionExtent.expand(1.3);	
	queryParams = "County= '" + countyName+"'";
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
	if (currentGraphicLayer)
	{
		currentGraphicLayer.refresh();
	}
}    	

//filter by Senate District
private function filterBySenateDistrict():void
{
	if (chk_distSenate.selected)  //don't bother to filter anything if filter isn't active
	{
		map.addEventListener(MapMouseEvent.MAP_CLICK, onSDClick);
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onMapClick);
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onHUCClick);
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onHDClick);
		countyBounds.clear(); 
		hucBounds.clear();
		
		if (dd_SenateDistricts.text=="All")  //as default, all districts are selected from dropdown
		{
			if (chk_project.selected)
			{
				queryParams = "ProjectType = '" + dd_ProjectType.text+"'";			
			}
			else
			{
				queryParams = "1=1";
			}				
		}
		else
		{		
			if (chk_project.selected)
			{
				queryParams = "ProjectType = '" + dd_ProjectType.text+"'" + "AND Dist_Senate= '" + dd_SenateDistricts.text+"'";			
			}
			else
			{
				queryParams = "Dist_Senate= '" + dd_SenateDistricts.text+"'";
				querySD.where = "District_N= '" + dd_SenateDistricts.text+"'";
				querySD.geometry = fullExtent;
				queryTaskSD.execute(querySD);			
			}
		}		
	}		
	else  //filter for project type, if applicable, otherwise clear filter
	{
		if (chk_distSenate.selected)
		{
			queryParams = "ProjectType = '" + dd_ProjectType.text+"'";			
		}
		else
		{
			queryParams = "1=1"
		}
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onMapClick);
		if (GraphicsLayer(currentGraphicLayer))
		{
			GraphicsLayer(currentGraphicLayer).clear();	
		}
	}
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
	
	if (currentGraphicLayer)
	{
		currentGraphicLayer.refresh();	
	}
}

private function SDQueryComplete(event:QueryEvent):void
{
	var fset:FeatureSet = event.featureSet;       
	var myFirstGraphic:Graphic = fset.features[0];
	
	if (myFirstGraphic)
	{
		unionExtentSD = Polygon(myFirstGraphic.geometry).extent;
	}
	else {return;}
	
	for each (var myGraphic1:Graphic in fset.features)
	{
		if (sdName == myGraphic1.attributes.District_N)
		{return;}
		
		else
		{
			sdBounds.clear();
			unionExtentSD = unionExtentSD.union(Polygon(myGraphic1.geometry).extent);
			myGraphic1.symbol = clickSymbol;
			sdBounds.add(myGraphic1);
			sdName= myGraphic1.attributes.District_N;
		}
	}
	dd_SenateDistricts.text = sdName;
	map.extent = unionExtentSD.expand(1.3);	
	queryParams = "Dist_Senate= '" + sdName+"'";
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
	if (currentGraphicLayer)
	{
		currentGraphicLayer.refresh();
	}
}    	

//filter by House District
private function filterByHouseDistrict():void
{
	if (chk_distHouse.selected)  //don't bother to filter anything if filter isn't active
	{
		map.addEventListener(MapMouseEvent.MAP_CLICK, onHDClick);
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onMapClick);
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onHUCClick);
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onSDClick);
		countyBounds.clear(); 
		hucBounds.clear();
		
		if (dd_HouseDistricts.text=="All")  //as default, all districts are selected from dropdown
		{
			if (chk_project.selected)
			{
				queryParams = "ProjectType = '" + dd_ProjectType.text+"'";			
			}
			else
			{
				queryParams = "1=1";
			}				
		}
		else
		{		
			if (chk_project.selected)
			{
				queryParams = "ProjectType = '" + dd_ProjectType.text+"'" + "AND Dist_House= '" + dd_HouseDistricts.text+"'";			
			}
			else
			{
				queryParams = "Dist_House= '" + dd_HouseDistricts.text+"'";
				//Alert.show(dd_HouseDistricts.text);
				queryHD.where = "District_N= '" + dd_HouseDistricts.text+"'";
				queryHD.geometry = fullExtent;
				queryTaskHD.execute(queryHD);			
			}
		}		
	}		
	else  //filter for project type, if applicable, otherwise clear filter
	{
		if (chk_distHouse.selected)
		{
			queryParams = "ProjectType = '" + dd_ProjectType.text+"'";			
		}
		else
		{
			queryParams = "1=1"
		}
		map.removeEventListener(MapMouseEvent.MAP_CLICK, onMapClick);
		if (GraphicsLayer(currentGraphicLayer))
		{
			GraphicsLayer(currentGraphicLayer).clear();	
		}
	}
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
	
	if (currentGraphicLayer)
	{
		currentGraphicLayer.refresh();	
	}
}

private function HDQueryComplete(event:QueryEvent):void
{
	var fset:FeatureSet = event.featureSet;       
	var myFirstGraphic:Graphic = fset.features[0];
	
	if (myFirstGraphic)
	{
		unionExtentHD = Polygon(myFirstGraphic.geometry).extent;
	}
	else {return;}
	
	for each (var myGraphic1:Graphic in fset.features)
	{
		if (hdName == myGraphic1.attributes.District_N)
		{return;}
			
		else
		{
			hdBounds.clear();
			unionExtentHD = unionExtentHD.union(Polygon(myGraphic1.geometry).extent);
			myGraphic1.symbol = clickSymbol;
			hdBounds.add(myGraphic1);
			hdName= myGraphic1.attributes.District_N;
		}
	}
	dd_HouseDistricts.text = hdName;
	map.extent = unionExtentHD.expand(1.3);	
	queryParams = "Dist_House= '" + hdName+"'";
	queryProjects.where = queryParams;
	queryTaskProjects.execute(queryProjects, new AsyncResponder(onQueryResult, myFaultFunction));
	if (currentGraphicLayer)
	{
		currentGraphicLayer.refresh();
	}
}    	

//Search for projects using Project Name field
private function doFindProjName():void
{
	if (select_Name.selected)
	{
		queryParams = "Upper(ProjectName)like Upper('%" + fText.text + "%')";	
	}
	else
	{
		queryParams = "Upper(ApplicationNbr) = Upper('" + fText.text + "')";
	}
	queryProjects.where = queryParams;
	queryProjects.geometry = map.extent;
	map.extent = fullExtent;
}

// clear records based on text input into search panel
private function clearSearch():void
{
	queryProjects.where = "1=1";
	queryProjects.geometry = fullExtent;
			
	if (currentGraphicLayer)
	{	
		currentGraphicLayer.clear();
	}
	
	if (hucBounds)
	{
		hucBounds.clear();
	}
	
	if (countyBounds)
	{
		countyBounds.clear();
	}
	
	if (sdBounds)
	{
		sdBounds.clear();
	}
	
	if (hdBounds)
	{
		hdBounds.clear();
	}
	
	if (chk_LyrProjAward.selected)
	{
		layerProjAwardDyn_Vis = true;
	}
	else if (chk_LyrProjType.selected)
	{
		layerProjTypeDyn_Vis = true;
	}		
}

private function onQueryResult( featureSet : FeatureSet, token : Object = null ) : void
 {
    var extent : Extent = map.extent;
    var graphic : Graphic = new Graphic;
    var results : ArrayCollection = new ArrayCollection;
    
	if (currentGraphicLayer)
	{	
		currentGraphicLayer.clear();
	}
	if (fText)
	{
		if (fText !=null)
		{
			extent = fullExtent;
			runQuery();
			return;
		}
		//else { return;}
	}
	
	//currentGraphicLayer.refresh();	
	if (currentScale < 3000000)
	{
		if (chk_LyrProjType.selected || chk_LyrProjAward.selected)
		{
			runQuery();
	 	}
	 	else { return;}
	}
	else { return;}
	
	function runQuery(): void
	{
        for each ( var myGraphic : Graphic in featureSet.features )
        {
            var graphicID:String=myGraphic.attributes.HotSpot + "." + myGraphic.attributes.OBJECTID;

			if (chk_LyrProjType.selected)
			{        	
	        	switch (myGraphic.attributes.ProjectType)
	        	{
	        		case "Acquisition":
	        			myGraphic.symbol = projAcquisition;
	        			break;
	        		case "Assessment":
	        			myGraphic.symbol = projAssessment;
	        			break;
	        		case "Council Support":
	        			myGraphic.symbol = projCouncil;
	        			break;
	        		case "Education":
	        			myGraphic.symbol = projEducation;
	        			break;
	        		case "Monitoring":
	        			myGraphic.symbol = projMonitoring;
	        			break;
					case "Outreach":
						myGraphic.symbol = projOutreach;
						break;
	        		case "Research":
	        			myGraphic.symbol = projResearch;
	        			break;
	        		case "Restoration":
	        			myGraphic.symbol = projRestoration;
	        			break;
	        		case "Technical Assistance":
	        			myGraphic.symbol = projTA;
	        			break;
	        	}
            }
			myGraphic.id = graphicID;
	       	myGraphic.toolTip = myGraphic.attributes.ProjectName + "\n" + "Project Type: "+ myGraphic.attributes.ProjectType+ "\n" + "Click on point for more information";
	       	myGraphic.addEventListener(MouseEvent.MOUSE_OVER, pointMouseOver);
	       	myGraphic.addEventListener(MouseEvent.MOUSE_OUT, pointMouseOut);
	       	//myGraphic.addEventListener(MouseEvent.CLICK, pointMouseClick);
			//myGraphic.toolTip = " ";
			//myGraphic.addEventListener(ToolTipEvent.TOOL_TIP_CREATE, projToolTipCreateHandler, false, 0, true);
			myGraphic.addEventListener(MouseEvent.CLICK, projInfoWindowCreateHandler);

	        if (currentGraphicLayer)
	        {
	        	GraphicsLayer(currentGraphicLayer).add( myGraphic );
	        }
		}
        if (currentGraphicLayer)
        {
        	currentGraphicLayer.refresh();
        }
 	
    // display number of points within current extent
	    var featuresInExtent:int = 0
	    for (var i : Number = 0 ; i < currentGraphicLayer.numChildren ; i++)
	    {   
	        graphic = currentGraphicLayer.getChildAt(i) as Graphic;
	        trace("GG:" + graphic.geometry );
	        featuresInExtent++;
	        
	        if (extent.contains(MapPoint(graphic.geometry)))
	        {   
	            results.addItem(graphic.attributes);
	        }
	    }
    
    if (featuresInExtent >499 && chk_LyrProjType.selected)
    {
    	info.text = ">500 projects in this extent, only the first 500 projects are displayed in the table";
		layerProjTypeDyn_Vis = true;  
    }
    
    else if(featuresInExtent >499 && chk_LyrProjAward.selected)
    {
    	info.text = ">500 projects in this extent, only the first 500 projects are displayed in the table";
    	layerProjAwardDyn_Vis = true;
    }
    else
    {
    	info.text = featuresInExtent + " projects in this extent ";
    	layerProjTypeDyn_Vis = false; 
    	layerProjAwardDyn_Vis = false;
    }

    // Create a new Sort Object
	var mySort:Sort = new Sort();
	
	// Create a SortField Object
	// The paramater is the field in the Array Collection to sort on
	var sortByLabel:SortField = new SortField("YearStart");
	
	// add Fields to your Sort Object. This is standard array notation so multiple sorts would be [sort1,sort2,sort3]
	mySort.fields=[sortByLabel];
	
	// set the sort object as the Array Collections sort
	results.sort=mySort;
	
	// refresh the Array Collection
	results.refresh();
    dg.dataProvider = results;	
	}
}
//updated infowindow on click event
protected function projInfoWindowCreateHandler(event:MouseEvent):void
{
	var graphic:Graphic = event.target as Graphic;
	const graphic:Graphic = Graphic(event.target);
	const mapPoint:MapPoint = MapPoint(graphic.geometry);
	
	//var content:Object = new Object();
	content.projectName = graphic.attributes.ProjectName;
	content.projectType = graphic.attributes.ProjectType;
	content.projectSummary = graphic.attributes.Summary;
	//content.projectStatus = graphic.attributes.Status;
	//content.projectStart = DateUtil.parseDate(graphic.attributes.DateGrantStart.toString());
	content.projectStart = graphic.attributes.DateGrantStart;
	//content.projectStart = formatDate(graphic.attributes.DateGrantStart);
	content.projectEnd = graphic.attributes.DateGrantEnd;
	content.projGrantee = graphic.attributes.Grantee;
	content.owriNBR = graphic.attributes.RI_ProjectNbr;
	
	//var popUpInfo:PopUpInfo = new PopUpInfo;
	//popUpInfo = content;
	//var myInfoPopup:PopUpRenderer = new PopUpRenderer;
	//myInfoPopup.popUpInfo = popUpInfo;

	//event.toolTip = ptt;
	
	// for infowindow:
	const point : Point = map.toScreen( mapPoint );
	map.infoWindow.show(map.toMap(point));
}

private function formatDate(DateGrantStart:Date):String
{
	var df:DateFormatter = new DateFormatter();
	df.formatString = "MM/DD/YYYY";
	return df.format(DateGrantStart);
}

//tooltip function for project points.. need to convert to infowindow (above)
/*protected function projToolTipCreateHandler(event:ToolTipEvent):void
{
	var graphic:Graphic = event.target as Graphic;
	const graphic:Graphic = Graphic(event.target);
	const mapPoint:MapPoint = MapPoint(graphic.geometry);
	ptt.projectName = graphic.attributes["ProjectName"];
	ptt.projectType = graphic.attributes["ProjectType"];
	ptt.projectSummary = graphic.attributes["Summary"];
	//ptt.projectStatus = graphic.attributes["Status"];
	//ptt.projectStart = DateUtil.parseDate(graphic.attributes["DateGrantStart"].toString());
	ptt.projectStart = graphic.attributes["DateGrantStart"];
	ptt.projectEnd = graphic.attributes["DateGrantEnd"];
	ptt.projGrantee = graphic.attributes["Grantee"];
	ptt.owriNBR = graphic.attributes["RI_ProjectNbr"];
	event.toolTip = ptt;
}*/

//perform identify task following map click event
/*private function pointMouseClick(event:MouseEvent):void
{
	const graphic:Graphic = Graphic(event.target);
	const mapPoint:MapPoint = MapPoint(graphic.geometry);
	content.projectName = graphic.attributes["ProjectName"];
	content.projectType = graphic.attributes["ProjectType"];
	content.projectSummary = graphic.attributes["Summary"];
	content.projectStatus = graphic.attributes["Status"];
	content.projectStart = graphic.attributes["DateGrantStart"];
	content.projectEnd = graphic.attributes["DateGrantEnd"];
	content.projGrantee = graphic.attributes["Grantee"];
	content.owriNBR = graphic.attributes["RI_ProjectNbr"];
	//content.imageURL = graphic.attributes["photo_URL"];
	const point : Point = map.toScreen( mapPoint );
	map.infoWindow.show(map.toMap(point));
}*/

// export function (listed below) borrowed from R. Scheitlin & Erwan Caredec: http://www.arcgis.com/home/item.html?id=5d4995ccdb99429185dfd8d8fb2a513e
private function exportToXLS():void
{
	try
	{
		var data:String = exportCSV(dg);
		var fileReference:FileReference = new FileReference();
		var currentDate:Date = new Date();
		var day:String = String(currentDate.getDate());
		var mo:String = String(currentDate.getMonth());
		var yr:String  = String(currentDate.getFullYear());
		var textDate:String = (yr + "_" + mo + "_" + day); 
		var defaultFileName:String = "oitt_" + textDate + "_.csv";
		
		/* if FileReference.save shows up as an unknow function
		when recompiling the flex viewer flex project sdk version is 
		below v 3.2 and the project's flash version is below 10.0.22.
		Download v3.2 and update the flash version to 10.0.22 or higher */				
		fileReference.save(data,defaultFileName);
	}
	catch(error:Error)
	{
		//Alert.show(error.message);
		Alert.show("You have not created a selection of records; please create a filter (e.g., by clicking on a watershed)");
	}
	exportCSV(dg);
}

private function exportCSV(dataGrid:DataGrid, csvSeparator:String=",", lineSeparator:String="\n"):String
{
	try
	{
		var data:String = "";
		var columnArray:Array = dataGrid.columns;
		var columnCount:int = columnArray.length;
		var dataGridColumn:DataGridColumn;
		var header:String = "";
		var headerGenerated:Boolean = false;
		var dataProvider:Object = dataGrid.dataProvider;
		
		//trace(ObjectUtil.toString(dataProvider));
		var rowCount:int = dataProvider.length;
		var dp:Object = null;
		var cursor:IViewCursor = dataProvider.createCursor();
		var j:int = 0;
		
		//loop through rows
		while (!cursor.afterLast)
		{
			var object:Object = null;
			object = cursor.current;
			//loop through all columns for the row
			for(var i:int = 0; i < columnCount; i++)
			{
				dataGridColumn = columnArray[i];
				//Exclude column data which is invisible (hidden)
				if(!dataGridColumn.visible)
				{
					continue;
				}
				data += "\""+ object[dataGridColumn.dataField] + "\"";
				//data += "\""+ dataGridColumn.itemToLabel(object)+ "\"";
				if(i < (columnCount -1))
				{
					data += csvSeparator;
				}
				//generate header of CSV, only if it's not genereted yet
				if (!headerGenerated)
				{
					header += "\"" + dataGridColumn.headerText + "\"";
					if (i < columnCount - 1)
					{
						header += csvSeparator;
					}
				}
			}
			headerGenerated = true;
			if (j < (rowCount - 1))
			{
				data += lineSeparator;
			}
			j++;
			cursor.moveNext ();
		}
		//set references to null:
		dataProvider = null;
		columnArray = null;
		dataGridColumn = null;		
	}
	catch(error:Error)
	{
		return null;
		Alert.show(error.message);
	}
	return (header + lineSeparator + data);
}

// start event handler for dg-map connection
 private function onItemClick(event:ListEvent) : void
{
	var graphic:Geometry = findGraphicByAttribute(event.itemRenderer.data).geometry;
	var gr: Graphic = findGraphicByAttribute(event.itemRenderer.data)
	var graphicExtent:Extent;
	var grPt:MapPoint;
	
	//Temporarily highlight selected graphic symbol
	var glow:Glow = new Glow(gr);
    glow.duration = 2000 ;
    glow.alphaFrom = 1 ;
    glow.alphaTo = .6 ;
    glow.blurXFrom = 30 ;
    glow.blurXTo = 0 ;
    glow.blurYFrom = 40 ;
    glow.blurYTo = 0 ;
    glow.strength = 70;
    glow.color = yellowFill.color;
    glow.play();
	
	//Center & Zoom to selected feature				
	grPt = MapPoint(graphic);
	map.centerAt(grPt);
	map.scale = 100000;
} 	
			
private function onItemRollOver( event : ListEvent ) : void
{
	var gr: Graphic = findGraphicByAttribute(event.itemRenderer.data)
	//gr.symbol = highlightedSymbol;
	var glow:Glow = new Glow(gr);
    glow.duration = 1000 ;
    glow.alphaFrom = 1 ;
    glow.alphaTo = 0 ;
    glow.blurXFrom = 20 ;
    glow.blurXTo = 0 ;
    glow.blurYFrom = 30 ;
    glow.blurYTo = 0 ;
    glow.strength = 40;
    glow.color = yellowFill.color;
    glow.play();
}

private function pointMouseOver( event : MouseEvent ) : void
{
  	var graphic : Graphic = Graphic( event.target );
	var glow:Glow = new Glow(graphic);
    glow.duration = 1000 ;
    glow.alphaFrom = 1 ;
    glow.alphaTo = 0 ;
    glow.blurXFrom = 20 ;
    glow.blurXTo = 0 ;
    glow.blurYFrom = 30 ;
    glow.blurYTo = 0 ;
    glow.strength = 40;
    glow.color = yellowFill.color;
    glow.play();
    			
  for each( var attributes : Object in dg.dataProvider )
  	{
		if (attributes === graphic.attributes)
		{
			dg.selectedIndex = (dg.dataProvider as ArrayCollection).getItemIndex(attributes);						
		}
	}	    	    
	dg.scrollToIndex(dg.selectedIndex);
}

private function pointMouseOut( event : MouseEvent ) : void
{   			   			    		
	dg.selectedIndex = -1;  			
}
// end event handler for dg-map connection

public function findGraphicByAttribute(attributes:Object):Graphic
{
	for each(var graphic:Graphic in currentGraphicLayer.graphicProvider)
	{
		if (graphic.attributes["OBJECTID"] == attributes["OBJECTID"])
		{
			return graphic;
		}
	}			
	return null;
}

//Geocoding Function
private function geocode():void
{
   	//clear any previous address point
   	myAddressPoint.clear();
    // Use outFields to get back extra information
    // The exact fields available depends on the specific Locator used.
    var myOutFields:Array = ["Loc_name"];
 
	var parameters:AddressToLocationsParameters = new AddressToLocationsParameters();
	
	parameters.address = { SingleLine: onelineaddress.text };
	
	// Use outFields to get back extra information
	// The exact fields available depends on the specific Locator used.
	parameters.outFields = [ "Loc_name" ];
	
	locator.addressToLocations(parameters, new AsyncResponder(onResult, onFault));
	function onResult(candidates:Array, token:Object = null):void
	{
		if (candidates.length > 0)
		{
			var addressCandidate:AddressCandidate = candidates[0];
			var myGraphic:Graphic = new Graphic();
			
			// for 9.3 servers, or anything else returning latlong:  myGraphic.geometry = WebMercatorUtil.geographicToWebMercator(addressCandidate.location);
			
			myGraphic.geometry = addressCandidate.location;
			myGraphic.symbol = addressSymbol;
			myGraphic.toolTip = addressCandidate.address.toString();
			myGraphic.id = "graphic";
			myAddressPoint.add(myGraphic);
			
			map.centerAt(myGraphic.geometry as MapPoint);
			
			// Zoom to an appropriate level
			// Note: your attribute and field value might differ depending on which Locator you are using...
			if (addressCandidate.attributes.Loc_name.search("RoofTop") > 0) // US_RoofTop
			{
				map.scale = 10000;
			}
			else if (addressCandidate.attributes.Loc_name.search("Address") > 0)
			{
				map.scale = 10000;
			}
			else if (addressCandidate.attributes.Loc_name.search("Street") > 0) // US_Streets, CAN_Streets, CAN_StreetName, EU_Street_Addr* or EU_Street_Name* 
			{
				map.scale = 15000;
			}
			else if (addressCandidate.attributes.Loc_name.search("ZIP4") > 0
				|| addressCandidate.attributes.Loc_name.search("Postcode") > 0) // US_ZIP4, CAN_Postcode
			{
				map.scale = 20000;
			}
			else if (addressCandidate.attributes.Loc_name.search("Zipcode") > 0) // US_Zipcode
			{
				map.scale = 40000;
			}
			else if (addressCandidate.attributes.Loc_name.search("City") > 0) // US_CityState, CAN_CityProv
			{
				map.scale = 150000;
			}
			else
			{
				map.scale = 500000;
			}
			myInfo.htmlText = "<b>Found:</b><br/>" + addressCandidate.address.toString(); // formated address
		}
		else
		{
			myInfo.htmlText = "<b><font color='#FF0000'>Found nothing :(</b></font>";
			
			Alert.show("Sorry, couldn't find a location for this address"
				+ "\nAddress: " + onelineaddress.text);
		};
	}
	
	function onFault(info:Object, token:Object = null):void
	{
		myInfo.htmlText = "<b>Failure</b>" + info.toString();
		Alert.show("Failure: \n" + info.toString());
	}
}

private function myFaultFunction(error:Object, clickGraphic:Graphic = null):void
{
    Alert.show(String(error), "Identify Error");
}

