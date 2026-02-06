/**
* Name: Pollution Grid
* Author: TrungNguyen (modularized by Claude)
* Description: Grid-based PM2.5 tracking with diffusion and decay
*/

model pollution_grid_model

// ==================== POLLUTION GRID SPECIES ====================
grid pollution_grid width: 50 height: 50 neighbors: 8 {
	
	// ==================== POLLUTION ATTRIBUTES ====================
	float pm25_level <- 0.0;
	float grid_value <- pm25_level update: pm25_level;  // Built-in for elevation
	
	// ==================== DECAY TRACKING ====================
	int last_decay_hour <- 0;
	
	// ==================== VISUALIZATION ====================
	rgb color <- get_pm25_color() update: get_pm25_color();
	
	// ==================== HOURLY DECAY REFLEX ====================
	reflex hourly_decay when: current_date.hour != last_decay_hour {
		pm25_level <- pm25_level * 0.9;  // 10% decay per hour
		last_decay_hour <- current_date.hour;
	}
	
	// ==================== COLOR CALCULATION (WHO Air Quality Scale) ====================
	rgb get_pm25_color {
		if pm25_level <= 12.0 {
			return rgb(0, 255, 0, 200);  // Good: Green
		} 
		else if pm25_level <= 35.0 {
			float ratio <- (pm25_level - 12.0) / (35.0 - 12.0);
			return rgb(255 * ratio, 255, 0, 200);  // Moderate: Yellow
		}
		else if pm25_level <= 55.0 {
			float ratio <- (pm25_level - 35.0) / (55.0 - 35.0);
			return rgb(255, 255 * (1 - ratio * 0.35), 0, 200);  // Unhealthy for Sensitive: Orange
		}
		else if pm25_level <= 150.0 {
			float ratio <- (pm25_level - 55.0) / (150.0 - 55.0);
			return rgb(255, 165 * (1 - ratio), 0, 200);  // Unhealthy: Red
		}
		else if pm25_level <= 250.0 {
			float ratio <- (pm25_level - 150.0) / (250.0 - 150.0);
			return rgb(255 - 126 * ratio, 0, 128 * ratio, 200);  // Very Unhealthy: Purple
		}
		else {
			return rgb(128, 0, 128, 200);  // Hazardous: Maroon
		}
	}
}
