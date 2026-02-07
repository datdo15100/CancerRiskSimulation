/**
* Name: Pollution Grid
* Author: TrungNguyen
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
	
	// ==================== COLOR CALCULATION (US EPA AQI Standard) ====================
	rgb get_pm25_color {
		int alpha <- 130;
		if pm25_level <= 12.0 {
			// Good: Green (#00E400)
			return rgb(0, 228, 0, alpha);
		}
		else if pm25_level <= 35.4 {
			// Good → Moderate: Green → Yellow (#FFFF00)
			float ratio <- (pm25_level - 12.0) / (35.4 - 12.0);
			return rgb(int(255 * ratio), int(228 + 27 * ratio), 0, alpha);
		}
		else if pm25_level <= 55.4 {
			// Moderate → USG: Yellow → Orange (#FF7E00)
			float ratio <- (pm25_level - 35.4) / (55.4 - 35.4);
			return rgb(255, int(255 - 129 * ratio), 0, alpha);
		}
		else if pm25_level <= 150.4 {
			// USG → Unhealthy: Orange → Red (#FF0000)
			float ratio <- (pm25_level - 55.4) / (150.4 - 55.4);
			return rgb(255, int(126 * (1 - ratio)), 0, alpha);
		}
		else if pm25_level <= 250.4 {
			// Unhealthy → Very Unhealthy: Red → Purple (#8F3F97)
			float ratio <- (pm25_level - 150.4) / (250.4 - 150.4);
			return rgb(int(255 - 112 * ratio), int(63 * ratio), int(151 * ratio), alpha);
		}
		else {
			// Hazardous: Maroon (#7E0023)
			return rgb(126, 0, 35, alpha);
		}
	}
}
