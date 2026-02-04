/**
* Name: buildings
* Based on the internal empty template. 
* Author: TrungNguyen
* Tags: 
*/


model cancer_risk_base

species building_base {
	int height;
	aspect asp_building{
		draw shape color: #pink border: #black //depth: dept
		;
	}

}


species road_base{
	float capacity;
	int nb_drivers;
	float speed_rate;
	aspect asp_road{
		draw (shape buffer(1 + 3 * (1 - speed_rate))) color: #blue;
	}
}