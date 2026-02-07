# Cancer Risk Simulation - Quick Start

Agent-Based Model of PM2.5 Exposure and Cancer Risk in Urban Environments

**GAMA Version:** 2025_06
**Repository:** https://github.com/datdo15100/CancerRiskSimulation.git

---

## Team Members

- **Nguyen Dang Trung** - 2440054
- **Do Thanh Dat** - 2440059
- **Nguyen Thanh Binh** - 2440052

---

## Quick Start

### 1. Install GAMA Platform
Download from: [gama-platform.org](https://gama-platform.org/download)
- **Required Version:** GAMA 2025_06 or later


### 2. Download Project
```bash
git clone https://github.com/datdo15100/CancerRiskSimulation.git
```

### 3. Open in GAMA
```
File → Import → Existing Projects into Workspace
→ Select CancerRiskSimulation folder
→ Click Finish
```

### 4. Run Simulation
```
Open: Project/models/Cancer_Risk_Simulate_Modular.gaml
Double-click: Cancer_Risk_Simulate (in Experiments tab)
```

---

## What You'll See

### Displays
1. **Pollution Map** - PM2.5 levels (green=good, red=hazardous)
2. **PM2.5 Analysis** - Time series charts
3. **Risk Distribution** - Cancer risk categories
4. **Dashboard** - Real-time statistics

### PM2.5 Color Scale (US EPA AQI)
- 🟢 **Green:** < 12 μg/m³ (Good)
- 🟡 **Yellow:** 12-35 μg/m³ (Moderate)
- 🟠 **Orange:** 35-55 μg/m³ (Unhealthy for Sensitive Groups)
- 🔴 **Red:** 55-150 μg/m³ (Unhealthy)
- 🟣 **Purple:** 150-250 μg/m³ (Very Unhealthy)
- 🟤 **Maroon:** >250 μg/m³ (Hazardous)

---

## 📁 Project Structure

```
Project/
├── models/
│   ├── Cancer_Risk_Simulate_Modular.gaml  # Main model
│   ├── Resident_WithRisk.gaml             # Resident agents
│   ├── PollutionGrid.gaml                 # PM2.5 grid
│   ├── Infrastructure.gaml                # Buildings/roads
│   ├── Infras_base.gaml                   # Base infrastructure
│   └── Inhabitant_base.gaml               # Base resident
└── includes/
    ├── building_polygon.shp               # Hanoi buildings (GIS)
    ├── building_polygon.dbf
    ├── building_polygon.shx
    ├── highway_line.shp                   # Hanoi roads (GIS)
    ├── highway_line.dbf
    └── highway_line.shx
```

---

## Model Overview

### Key Components

| Component | Count | Description |
|-----------|-------|-------------|
| **Residents** | 3000-8000 | Agents that commute daily, emit PM2.5 |
| **Buildings** | ~500 | Homes and workplaces (from OSM) |
| **Roads** | ~200 | Traffic network (from OSM) |
| **Pollution Grid** | 2500 (50×50) | PM2.5 diffusion and decay |

### Agent Characteristics
- **Gender:** 60% male, 40% female
- **Smoking:** 30% of population
- **Obesity:** 30% of population
- **Family History:** 12.5% of population
- **Mask Wearing:** 85% of population

### Daily Routine
```
06:00-09:00  Morning commute (home → work)
09:00-14:00  At work (8 hours)
14:00-17:00  Evening commute (work → home)
17:00-06:00  At home
```

---

## Key Formulas

### PM2.5 Emission
```
emission = 10-20 μg/m³ per step (when traveling)
step = 60 seconds
```

### Cancer Risk Calculation
```
cumulative_risk = Σ (PM2.5_dose × omega_pm)
risk_probability = sigmoid(cumulative_risk + baseline_risk)

Baseline Risk Factors:
  - Male:           +0.3
  - Smoking:        +0.6
  - Obesity:        +0.3
  - Family History: +0.4
  - Mask Wearing:   -60% PM2.5 exposure
```

---

## Experiments

### GUI Experiment (Interactive)
- Real-time visualization
- Adjustable parameters
- 4 displays with charts

### Batch Experiment (Automated)
Three scenarios for comparison:

| Scenario | Smoking | Obesity | Masks | Emissions |
|----------|---------|---------|-------|-----------|
| **0 - Baseline** | 30% | 30% | 85% | 100% |
| **1 - Unhealthy Lifestyle** | 80% | 60% | 10% | 100% |
| **2 - Clean Air** | 30% | 30% | 85% | 0% |

**Run:** Right-click `Batch_Scenarios` → Run Experiment

---

## Expected Results

### After 8 Hours
- **Avg PM2.5:** 100-180 μg/m³ (during rush hours)
- **Avg Cancer Risk:** 12-18%
- **High Risk (>50%):** 3-5% of population

### After 24 Hours
- **Avg Cancer Risk:** 18-25%
- **High Risk (>50%):** 8-12% of population
- **Very High Risk (>80%):** 1-3% of population

### Spatial Patterns
- High PM2.5 along major roads during rush hours
- Gradient from roads to residential areas
- Risk hotspots near high-traffic intersections

---

## Key Parameters (Adjustable)


### Population
- **Initial Population:** 100-10000 (default: 3000)
- **Resident Speed:** 0.1-5.0 m/s (default: 5.0)

### Environment
- **Emission Multiplier:** 0-5 (default: 1.0)
- **Mask Effectiveness:** 0-1 (default: 0.6)

### Risk Model
- **PM Weight (omega_pm):** 0.001-0.1 (default: 0.03)
- **PM Reference:** 50-500 μg/m³ (default: 150)


### System Architecture
This is the species description and their relation as described in the figure:

![Model Architecture](https://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/datdo15100/CancerRiskSimulation/test_branch_grid/Cancer_Risk_Simulation_Simple.puml)

---

## Troubleshooting

### Simulation Too Slow
→ Reduce `initial_population` to 1000-3000

### Cannot Find Shapefiles
→ Verify `includes/` folder has `.shp`, `.dbf`, `.shx` files
