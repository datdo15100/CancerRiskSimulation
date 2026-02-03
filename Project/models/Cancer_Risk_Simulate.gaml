/**
* Name: TrafficGIS
* Based on the internal skeleton template. 
* Author: trungnd
* Tags: 
*/

model Cancer_Risk_Simulate

global {

	float step <- 10;
	float dept <- rnd(250.0);
	
	file shapefile_buildings <- file("../includes/buildings.shp");
	file shapefile_roads <- file("../includes/roads.shp");
	
	map<road,float> road_weights;
	geometry shape <- envelope(shapefile_roads);
	
	graph road_network;
	//creation of buildings, roads, and inhabitants.
	init{
		create building from: shapefile_buildings with:(height:int(read("HEIGHT")))
		;
		create road from: shapefile_roads;
		create inhabitant number: 500{
			location <- any_location_in(one_of(building));
		}
		road_network <- as_edge_graph(road);
	}
	reflex update_speed{
		road_weights <- road as_map(each::each.shape.perimeter/each.speed_rate);
	}
}

grid plot height:50#m width: 50#m{
	float pollution_rate <- 0.0;
	
} 

species building{
	int height;
	aspect asp_building{
		draw shape color: #pink border: #black //depth: dept
		;
	}
	aspect threeD{
		draw shape color: #cyan depth: height texture: ["../includes/roof.png",
		"../includes/texture1.jpg"];
	}
}
species road{
	float capacity <- 1 + shape.perimeter/30;
	int nb_drivers <- 0 update: length(inhabitant at_distance 1);
	float speed_rate <- 1.0 update: exp(-nb_drivers/capacity) min: 0.1;
	aspect asp_road{
		draw (shape buffer(1 + 3 * (1 - speed_rate))) color: #blue;
	}
}

species inhabitant skills: [moving]{
	point target;
	rgb color <- rnd_color(255);
	float proba_leave <- 0.05;
	float speed <- 5 #km/#h;
	reflex leave when: (target = nil) and (flip(proba_leave)){
		target <- any_location_in(one_of(building));
	}
	reflex move when: (target != nil){
		do goto target: target on: road_network move_weights: road_weights;
		if (location = target){
			target <- nil;
		}
	}
	aspect 3D{
		draw pyramid(4) color: color;
		draw sphere(2) at: location + {0,0,3} color: color;
	}
}

experiment TrafficGIS type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display view type: 3d axes: false background: #white{
			image "../includes/satelitte.png" refresh: false transparency: 0.2;
			//grid plot border: #green;
			species building aspect: threeD 
			//asp_building
			;
			species road aspect: asp_road;
			species inhabitant aspect: 3D;
		}
	}
}
