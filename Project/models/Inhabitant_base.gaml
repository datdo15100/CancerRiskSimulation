/**
* Name: inhabitantl
* Based on the internal empty template. 
* Author: TrungNguyen
* Tags: 
*/


model cancer_risk_base



global {
	// color present for inhabitant health :3
	rgb color_1 <- rgb ("yellow");
	rgb color_2 <- rgb ("red");
	rgb color_3 <- rgb ("blue");
	rgb color_4 <- rgb ("orange");
	rgb color_5 <- rgb ("green");
	rgb color_6 <- rgb ("pink");   
	rgb color_7 <- rgb ("magenta");
	rgb color_8 <- rgb ("cyan");


}


species inhabitant_base {
	
	float speed <- 5;
	bool sex;
	float bmi;
	rgb color;
//		
//	bool has_mask <- true;
//	bool is_smoking <- true;

}

