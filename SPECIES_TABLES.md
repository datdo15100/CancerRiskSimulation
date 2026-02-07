# Species Description Tables

Complete specification of all species in the Cancer Risk Simulation model.

---

## 📊 Table of Contents

1. [Building Species](#building-species)
2. [Road Species](#road-species)
3. [Resident Species](#resident-species)
4. [Pollution Grid Species](#pollution-grid-species)
5. [Summary Comparison](#summary-comparison)

---

## 🏢 Building Species

**File:** `Infrastructure.gaml`
**Parent:** `building_base`
**Type:** Static infrastructure
**Count:** ~500 (loaded from shapefile)

### Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `height` | int | From shapefile | - | Building height in meters |
| `residents_inside` | list\<resident\> | [] (empty) | Dynamic | List of residents currently inside |
| `shape` | geometry | From shapefile | - | Polygon geometry of building |
| `location` | point | Centroid | - | Center point of building |

### Reflexes / Behaviors

**None** - Buildings are static infrastructure with no autonomous behaviors.

### Actions

| Action | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `add_resident` | `resident r` | void | Adds a resident to `residents_inside` list |
| `remove_resident` | `resident r` | void | Removes a resident from `residents_inside` list |
| `get_occupancy` | - | int | Returns number of residents inside |
| `is_empty` | - | bool | Returns true if no residents inside |

### Visualization

```gaml
aspect asp_building {
    draw shape color: #gray border: #black depth: height;
}
```

**Purpose:** Represents homes and workplaces where residents spend time. Tracks occupancy for statistics and visualization.

---

## 🛣️ Road Species

**File:** `Infrastructure.gaml`
**Parent:** `road_base`
**Type:** Dynamic network infrastructure
**Count:** ~200 (loaded from shapefile)

### Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `capacity` | float | 1 + perimeter/30 | - | Maximum traffic capacity |
| `nb_drivers` | int | 0 | Every step | Number of nearby residents (within 1m) |
| `speed_rate` | float | 1.0 | Every step | Speed coefficient (0.1-1.0) based on congestion |
| `shape` | geometry | From shapefile | - | Line geometry of road |
| `perimeter` | float | Calculated | - | Length of road segment |

### Reflexes / Behaviors

| Reflex | Trigger | Action | Description |
|--------|---------|--------|-------------|
| `update nb_drivers` | Every step | `nb_drivers <- count_nearby_residents()` | Counts residents within 1m of road |
| `update speed_rate` | Every step | `speed_rate <- calculate_speed_rate()` | Recalculates speed based on traffic |

### Actions

| Action | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `count_nearby_residents` | - | int | `length(resident at_distance 1)` |
| `calculate_speed_rate` | - | float | `exp(-nb_drivers / capacity)` |
| `is_congested` | - | bool | Returns true if `speed_rate < 0.3` |
| `get_congestion_level` | - | float | Returns `1.0 - speed_rate` |

### Formula

**Traffic Congestion Model:**
```
speed_rate = e^(-nb_drivers / capacity)

Road Weight (for pathfinding):
weight = perimeter / speed_rate
```

**Interpretation:**
- Empty road: `nb_drivers=0` → `speed_rate=1.0` → minimum weight (fast)
- Congested: `nb_drivers=capacity` → `speed_rate≈0.37` → high weight (slow)

### Visualization

```gaml
aspect asp_road {
    draw shape color: rgb(50, 50, 50) width: 3;
}
```

**Purpose:** Dynamic road network that responds to traffic. Higher congestion reduces movement speed, creating realistic traffic patterns and longer pollution exposure times.

---

## 👤 Resident Species

**File:** `Resident_WithRisk.gaml`
**Parent:** `inhabitant_base`
**Skills:** `[moving]`
**Type:** Autonomous agents
**Count:** 3000-8000 (user-defined parameter)

### Personal Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `is_male` | bool | `flip(0.6)` | - | Gender (60% male, 40% female) |
| `is_smoke` | bool | `flip(0.3)` | - | Smoking status (30% smokers) |
| `is_obese` | bool | `flip(0.3)` | - | Obesity status (30% obese) |
| `is_family_history` | bool | `flip(0.125)` | - | Family cancer history (12.5%) |
| `is_wearmask` | bool | `flip(0.85)` | - | Mask-wearing behavior (85%) |

### Location Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `location` | point | Random in building | Every step | Current position |
| `home_building` | building | Random | At init | Assigned home |
| `home_location` | point | In home_building | - | Home coordinates |
| `work_building` | building | Random (≠home) | At init | Assigned workplace |
| `work_location` | point | In work_building | - | Work coordinates |
| `current_building` | building | home_building | Dynamic | Current building (if inside) |
| `is_inside_building` | bool | true | Dynamic | Indoor/outdoor status |

### Movement Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `target` | point | nil | Dynamic | Movement destination |
| `target_building` | building | nil | Dynamic | Destination building |
| `speed` | float | 5.0 m/s | - | Movement speed |
| `last_location` | point | location | Every step | Previous position (for stuck detection) |
| `stuck_counter` | int | 0 | Every step | Steps without movement |
| `reassignment_count` | int | 0 | When reassigned | Number of reassignments |

### Emission Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `emission_pm` | float | 0.0 | When traveling | PM2.5 emission per step (μg/m³) |
| `base_emission_rate` | float | 10-20 (random) | - | Base emission rate (μg/m³/step) |

### Risk Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `baseline_risk` | float | Calculated | At init | Baseline risk from lifestyle factors |
| `cumulative_risk_score` | float | 0.0 | Every step | Accumulated risk over time |
| `risk_probability` | float | 0.0 | Every step | Cancer risk probability (0-1) |
| `pm_dose` | float | 0.0 | Every step | PM2.5 dose per step |
| `total_pm_exposure` | float | 0.0 | Every step | Total cumulative PM2.5 exposure |
| `current_pm_zone` | float | 0.0 | Every step | Current PM2.5 at location |
| `theta` | float | 1.0 | Dynamic | Exposure factor (1.0 outdoor, 0.3 indoor) |
| `protect` | float | 1.0 or 0.4 | Dynamic | Protection factor (0.4 if mask, 1.0 if no mask) |

### Schedule Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `work_start_hour` | int | 6-9 (random) | - | Work start time (6am-9am) |
| `work_duration` | int | 8 | - | Hours at work |
| `time_entered_building` | date | nil | When enters | Timestamp of building entry |

### Main Reflexes / Behaviors

| Reflex | Trigger Condition | Actions | Description |
|--------|-------------------|---------|-------------|
| `go_to_work` | `hour = work_start_hour` AND `target = nil` AND `current_building = home_building` | Set `target <- work_location`<br>Set `target_building <- work_building`<br>Call `exit_building()` | Leave home and start morning commute |
| `go_home` | `current_building = work_building` AND `(current_date - time_entered_building) >= 8h` | Set `target <- home_location`<br>Set `target_building <- home_building`<br>Call `exit_building()` | Leave work after 8 hours and start evening commute |
| `move` | `target != nil` AND `not is_inside_building` | `calculate_emission()`<br>`move_towards_target()`<br>`emit_pollution()`<br>`check_if_stuck_and_reassign()`<br>`check_arrival()` | Main movement behavior: move on network, emit PM2.5, check status |
| `update_risk` | Always (every step) | `update_exposure_factors()`<br>`get_current_pm_zone()`<br>`calculate_pm_dose()`<br>`update_cumulative_risk()`<br>`calculate_risk_probability()` | Update cancer risk calculation |
| `zero_emission_inside` | `is_inside_building` | `emission_pm <- 0.0` | Stop emission when inside building |

### Key Actions

| Action | Parameters | Description | Formula |
|--------|------------|-------------|---------|
| `initialize_home` | - | Assign random home building and location | |
| `initialize_work` | - | Assign random work building (≠home) | |
| `calculate_baseline_risk` | - | Compute baseline risk from traits | `baseline_risk = Σ(trait_weights)`<br>Male: +0.3<br>Smoke: +0.6<br>Obese: +0.3<br>Family: +0.4 |
| `calculate_emission` | - | Compute PM2.5 emission | `emission_pm = emission_multiplier × base_emission_rate` |
| `move_towards_target` | - | Move on road network | `goto target: target on: road_network` |
| `emit_pollution` | - | Add PM2.5 to current grid cell | `pm25_level += emission_pm` |
| `check_if_stuck_and_reassign` | - | Detect stuck agents and reassign destination | If `distance_moved < 0.1` for 20 steps → reassign |
| `check_arrival` | - | Check if reached destination | If `distance_to_target <= 10m` → enter building |
| `update_exposure_factors` | - | Update theta and protect based on location | `theta = 1.0` (outdoor) or `0.3` (indoor)<br>`protect = 0.4` (mask) or `1.0` (no mask) |
| `get_current_pm_zone` | - | Get PM2.5 level at current location | `current_pm_zone = grid_cell.pm25_level` |
| `calculate_pm_dose` | - | Calculate PM2.5 dose | `pm_dose = current_pm_zone × (step/3600) × theta × protect` |
| `update_cumulative_risk` | - | Update cumulative risk score | `X_pm = min(1.0, pm_dose / PM_ref)`<br>`risk_increment = omega_pm × X_pm`<br>`cumulative_risk_score += risk_increment` |
| `calculate_risk_probability` | - | Calculate cancer risk probability | `z = k × (cumulative_risk_score + baseline_risk) + b`<br>`risk_probability = 1 / (1 + e^(-z))`<br>where k=2.0, b=-4.0 |
| `enter_building` | `building b` | Enter a building, stop emission | Set `is_inside_building=true`<br>Set `current_building=b`<br>Add self to building's resident list |
| `exit_building` | - | Exit current building | Remove self from building's resident list<br>Set `is_inside_building=false` |
| `reassign_to_nearest_reachable_building` | - | Find alternative destination | Search within 200m radius<br>Pick closest building ≠ home ≠ work |

### Visualization

```gaml
aspect default {
    rgb risk_color <- get_risk_color();  // Green/Yellow/Orange/Red based on risk
    if is_male {
        draw triangle(6) color: risk_color border: #black;  // Male = triangle
    } else {
        draw circle(3) color: risk_color border: #black;    // Female = circle
    }
}
```

**Risk Color Mapping:**
- Green: risk < 20%
- Yellow: 20% ≤ risk < 50%
- Orange: 50% ≤ risk < 80%
- Red: risk ≥ 80%

**Purpose:** Autonomous agents that represent individual residents. They commute daily between home and work, emit PM2.5 pollution during travel, and accumulate cancer risk based on exposure and lifestyle factors.

---

## 🌫️ Pollution Grid Species

**File:** `PollutionGrid.gaml`
**Type:** Grid (spatial environment)
**Dimensions:** 50 × 50 = 2500 cells
**Neighbors:** 8 (Moore neighborhood)

### Grid Configuration

```gaml
grid pollution_grid width: 50 height: 50 neighbors: 8 { ... }
```

### Attributes

| Attribute | Type | Initial Value | Update Rule | Description |
|-----------|------|---------------|-------------|-------------|
| `pm25_level` | float | 0.0 | Every step | PM2.5 concentration (μg/m³) |
| `grid_value` | float | pm25_level | Every step | Copy of pm25_level (used for 3D elevation) |
| `color` | rgb | Calculated | Every step | Display color based on PM2.5 level |
| `last_decay_hour` | int | 0 | Hourly | Hour of last decay (for hourly trigger) |

### Reflexes / Behaviors

| Reflex | Trigger Condition | Action | Description |
|--------|-------------------|--------|-------------|
| `hourly_decay` | `current_date.hour != last_decay_hour` | `pm25_level <- pm25_level × 0.9`<br>`last_decay_hour <- current_date.hour` | 10% decay per hour (half-life ≈ 6.6 hours) |
| `update grid_value` | Every step | `grid_value <- pm25_level` | Update elevation value for 3D display |
| `update color` | Every step | `color <- get_pm25_color()` | Update color based on current PM2.5 |

### Actions

| Action | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `get_pm25_color` | - | rgb | Calculate EPA AQI color based on PM2.5 level |

### Color Calculation (US EPA AQI Standard)

| PM2.5 Range (μg/m³) | Color | RGB | AQI Category |
|---------------------|-------|-----|--------------|
| 0 - 12.0 | 🟢 Green | (0, 228, 0) | Good |
| 12.0 - 35.4 | 🟡 Yellow | (255, 255, 0) | Moderate |
| 35.4 - 55.4 | 🟠 Orange | (255, 126, 0) | Unhealthy for Sensitive Groups |
| 55.4 - 150.4 | 🔴 Red | (255, 0, 0) | Unhealthy |
| 150.4 - 250.4 | 🟣 Purple | (143, 63, 151) | Very Unhealthy |
| > 250.4 | 🟤 Maroon | (126, 0, 35) | Hazardous |

**Implementation:** Linear interpolation between thresholds for smooth gradients.

### Global Operations (Not in Grid Reflex)

These operations are performed by the global model:

#### Diffusion (Hourly)
```gaml
// In Cancer_Risk_Simulate_Modular.gaml
reflex pm25_diffusion when: current_date.hour != last_diffusion_hour {
    diffuse var: pm25_level on: pollution_grid proportion: 0.6;
    last_diffusion_hour <- current_date.hour;
}
```

**Mechanism:**
- 60% of PM2.5 flows to 8 neighbors (7.5% each)
- 40% remains in current cell
- Uses GAMA built-in diffusion operator

#### Emission (Every Step by Residents)
```gaml
// In Resident_WithRisk.gaml
action emit_pollution {
    pollution_grid current_cell <- pollution_grid(location);
    if current_cell != nil {
        ask current_cell {
            pm25_level <- pm25_level + myself.emission_pm;
        }
    }
}
```

### Visualization

```gaml
// 2D Display
display "Pollution Map" type: 2d {
    grid pollution_grid;  // Color automatically from 'color' attribute
}

// 3D Display (optional)
display "3D View" type: 3d {
    grid pollution_grid elevation: grid_value * 0.5 triangulation: true;
}
```

**Purpose:** Spatial representation of PM2.5 pollution. Models diffusion (spreading), decay (natural dispersion), and accumulation from resident emissions. Provides visual feedback using EPA color standards.

---

## 📊 Summary Comparison

### Species Overview Table

| Species | Type | Count | Autonomous? | Key Function |
|---------|------|-------|-------------|--------------|
| **Building** | Static infrastructure | ~500 | No | Home/work locations, occupancy tracking |
| **Road** | Dynamic infrastructure | ~200 | No (but updates) | Traffic network, congestion modeling |
| **Resident** | Agent | 3000-8000 | Yes | Daily commute, PM2.5 emission, risk accumulation |
| **Pollution Grid** | Spatial grid | 2500 (50×50) | No (but reacts) | PM2.5 diffusion, decay, visualization |

### Attributes Count

| Species | Total Attributes | Dynamic Attributes | Static Attributes |
|---------|------------------|-------------------|-------------------|
| Building | 4 | 1 (residents_inside) | 3 (height, shape, location) |
| Road | 5 | 2 (nb_drivers, speed_rate) | 3 (capacity, shape, perimeter) |
| Resident | 30+ | 20+ (location, risk, emissions, etc.) | 10 (traits, home/work buildings) |
| Pollution Grid | 4 | 3 (pm25_level, grid_value, color) | 1 (last_decay_hour) |

### Reflexes Count

| Species | Reflexes | Actions | Purpose |
|---------|----------|---------|---------|
| Building | 0 | 4 | Occupancy management |
| Road | 2 | 4 | Traffic dynamics |
| Resident | 5 | 20+ | Movement, emission, risk calculation |
| Pollution Grid | 3 | 1 | Decay, visualization |

### Interaction Matrix

|  | Building | Road | Resident | Pollution Grid |
|---|----------|------|----------|----------------|
| **Building** | - | Connected via location | Residents enter/exit | - |
| **Road** | - | - | Residents move on network | - |
| **Resident** | Enter/exit | Move on, affect congestion | - | Emit PM2.5, absorb exposure |
| **Pollution Grid** | - | - | Residents emit/absorb | Diffusion between cells |

---

## 🔄 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  SIMULATION CYCLE                       │
│                                                          │
│  ┌──────────────┐     ┌──────────────┐                 │
│  │   Building   │────►│     Road     │                 │
│  │  (Static)    │     │  (Dynamic)   │                 │
│  └──────┬───────┘     └──────┬───────┘                 │
│         │ Provide            │ Provide                  │
│         │ Locations          │ Network                  │
│         ▼                    ▼                          │
│  ┌─────────────────────────────────┐                   │
│  │         Resident                │                   │
│  │  1. Check schedule (go_to_work) │                   │
│  │  2. Move on road network        │                   │
│  │  3. Emit PM2.5 to grid         │───────┐           │
│  │  4. Absorb PM2.5 from grid     │◄──────┤           │
│  │  5. Calculate risk              │       │           │
│  └─────────────────────────────────┘       │           │
│                                            ▼           │
│                                   ┌──────────────────┐ │
│                                   │ Pollution Grid   │ │
│                                   │ 1. Receive PM2.5 │ │
│                                   │ 2. Diffuse (1/h) │ │
│                                   │ 3. Decay (1/h)   │ │
│                                   │ 4. Visualize     │ │
│                                   └──────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Notes for Presentation

### Key Points to Emphasize:

1. **Modularity:** Each species has clear responsibilities
   - Building: Location provider
   - Road: Network provider + traffic dynamics
   - Resident: Active agent with complex behaviors
   - Pollution Grid: Environmental state + visualization

2. **Heterogeneity:** Residents have 5 binary traits → 2^5 = 32 possible combinations
   - Creates realistic population diversity
   - Different risk profiles emerge naturally

3. **Spatial-Temporal Coupling:**
   - Residents emit PM2.5 at their location
   - Grid diffuses PM2.5 spatially
   - Residents absorb PM2.5 at their location
   - Creates emergent pollution patterns

4. **Feedback Loops:**
   - Traffic congestion → slower movement → longer exposure
   - High PM2.5 → higher risk → visual feedback (red agents)

5. **Computational Efficiency:**
   - Buildings/roads are lightweight (few dynamic attributes)
   - Grid uses built-in GAMA diffusion (optimized)
   - Resident complexity is necessary for realistic behavior

---

**Use these tables in your presentation slides to clearly demonstrate your understanding of the model structure!**
