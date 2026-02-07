# UML Diagrams - Cancer Risk Simulation

Comprehensive UML diagrams for the Agent-Based Model of PM2.5 Exposure and Cancer Risk.

---

## 1. Class Diagram - Species Architecture

```mermaid
classDiagram
    class Building {
        -string type
        -int capacity
        -list~Resident~ residents_inside
        -geometry shape
        +add_resident(Resident r)
        +remove_resident(Resident r)
        +get_resident_count() int
        +is_available() bool
    }

    class Road {
        -float speed_rate
        -float congestion_level
        -int traffic_count
        -geometry shape
        -rgb color
        +update_traffic()
        +update_color()
        +calculate_congestion() float
        +get_weight() float
    }

    class Resident {
        -bool is_male
        -bool is_smoke
        -bool is_obese
        -bool is_family_history
        -bool is_wearmask
        -Building home_building
        -Building work_building
        -Building current_building
        -point target
        -float speed
        -float emission_pm
        -float base_emission_rate
        -float pm_dose
        -float baseline_risk
        -float cumulative_risk_score
        -float risk_probability
        -bool is_inside_building
        -int work_start_hour
        -int work_duration
        -int stuck_counter
        -int reassignment_count
        +initialize_attributes()
        +schedule_day()
        +move()
        +calculate_emission()
        +emit_pollution()
        +absorb_pm25()
        +update_risk()
        +enter_building(Building b)
        +exit_building()
        +check_if_stuck_and_reassign()
        +get_risk_color() rgb
    }

    class PollutionGrid {
        -float pm25_level
        -float grid_value
        -int last_decay_hour
        -rgb color
        +hourly_decay()
        +get_pm25_color() rgb
    }

    class Global {
        -int initial_population
        -float resident_speed
        -float emission_multiplier
        -float mask_effectiveness
        -float omega_pm
        -float PM_ref
        -graph road_network
        -map road_weights
        +initialize_buildings()
        +initialize_roads()
        +initialize_residents()
        +initialize_network()
        +pm25_diffusion()
        +update_road_weights()
    }

    Resident "0..*" --> "1" Building : home_building
    Resident "0..*" --> "1" Building : work_building
    Resident "0..1" --> "0..1" Building : current_building
    Resident --> "1" PollutionGrid : absorbs from
    Resident --> "1" PollutionGrid : emits to
    Resident --> Road : travels on
    Building "1" --> "0..*" Resident : contains
    Road --> Global : updates weights
    PollutionGrid --> PollutionGrid : diffuses to neighbors
    Global --> Building : manages
    Global --> Road : manages
    Global --> Resident : manages
    Global --> PollutionGrid : manages
```

---

## 2. Sequence Diagram - Morning Commute Flow

```mermaid
sequenceDiagram
    participant R as Resident
    participant Home as Home Building
    participant Grid as Pollution Grid
    participant Road as Road Network
    participant Work as Work Building
    participant Global as Global Model

    Note over R: 06:00 - Work Start Hour

    R->>R: schedule_day() - Set target to work
    R->>Home: exit_building()
    Home->>Home: remove_resident(R)
    R->>R: is_inside_building = false

    loop While traveling (every step)
        R->>R: calculate_emission()
        Note over R: emission = 10-20 μg/m³

        R->>Road: goto(target) on road_network
        Road->>Road: update_traffic()
        Road->>Road: calculate_congestion()

        R->>Grid: emit_pollution()
        Grid->>Grid: pm25_level += emission_pm

        R->>Grid: absorb_pm25()
        Grid->>R: return pm25_level
        R->>R: pm_dose = pm25 * (1 - mask * 0.6)

        R->>R: update_risk()
        R->>R: cumulative_risk_score += dose * omega_pm
        R->>R: calculate_risk_probability()

        R->>R: check_if_stuck_and_reassign()
        alt Stuck > 10 steps
            R->>R: reassign_to_nearest_reachable_building()
        end

        R->>R: check_arrival()
        alt Distance < 5m
            R->>Work: enter_building()
            Work->>Work: add_resident(R)
            R->>R: is_inside_building = true
        end
    end

    Note over Global: Hourly Reflex
    Global->>Global: pm25_diffusion()
    Global->>Grid: diffuse(proportion: 0.6)
    Grid->>Grid: hourly_decay() - 10% reduction
```

---

## 3. Activity Diagram - Resident Daily Cycle

```mermaid
flowchart TD
    Start([Simulation Start]) --> Init[Initialize Resident]
    Init --> SetHome[Assign Home Building]
    SetHome --> SetWork[Assign Work Building]
    SetWork --> SetAttrs[Set Personal Attributes]
    SetAttrs --> CalcBaseline[Calculate Baseline Risk]

    CalcBaseline --> CheckTime{Check Time}

    CheckTime -->|06:00-09:00| SetWorkTarget[Set Target: Work]
    CheckTime -->|09:00-14:00| AtWork[At Work Building]
    CheckTime -->|14:00-17:00| SetHomeTarget[Set Target: Home]
    CheckTime -->|17:00-06:00| AtHome[At Home Building]

    SetWorkTarget --> ExitHome[Exit Home]
    ExitHome --> Travel1[Travel to Work]

    SetHomeTarget --> ExitWork[Exit Work]
    ExitWork --> Travel2[Travel to Home]

    Travel1 --> Move{Move Reflex}
    Travel2 --> Move

    Move --> CalcEmission[Calculate Emission]
    CalcEmission --> Emit[Emit PM2.5 to Grid]
    Emit --> Absorb[Absorb PM2.5 from Grid]
    Absorb --> UpdateRisk[Update Cumulative Risk]
    UpdateRisk --> CalcProb[Calculate Risk Probability]
    CalcProb --> CheckStuck{Stuck?}

    CheckStuck -->|Yes, >10 steps| Reassign[Reassign Building]
    CheckStuck -->|No| CheckArrival{Arrived?}

    Reassign --> CheckArrival

    CheckArrival -->|Distance < 5m| Enter[Enter Building]
    CheckArrival -->|Still moving| Move

    Enter --> CheckTime
    AtWork --> CheckTime
    AtHome --> CheckTime

    CheckTime --> End{Simulation End?}
    End -->|No| CheckTime
    End -->|Yes| Stop([Stop])
```

---

## 4. State Diagram - Resident Behavior States

```mermaid
stateDiagram-v2
    [*] --> Initialized

    Initialized --> AtHome : Set home_building

    AtHome --> TravelingToWork : 06:00-09:00 work_start_hour
    TravelingToWork --> AtWork : Distance < 5m

    AtWork --> TravelingHome : 14:00-17:00 (work_start + duration)
    TravelingHome --> AtHome : Distance < 5m

    TravelingToWork --> Stuck : stuck_counter >= 10
    TravelingHome --> Stuck : stuck_counter >= 10

    Stuck --> TravelingToWork : Reassign work_building
    Stuck --> TravelingHome : Reassign home_building

    state TravelingToWork {
        [*] --> Moving
        Moving --> Emitting : Every step
        Emitting --> Absorbing
        Absorbing --> UpdatingRisk
        UpdatingRisk --> Moving
    }

    state TravelingHome {
        [*] --> Moving
        Moving --> Emitting : Every step
        Emitting --> Absorbing
        Absorbing --> UpdatingRisk
        UpdatingRisk --> Moving
    }

    state AtHome {
        [*] --> Resting
        Resting --> AbsorbingIndoor : Every step
        AbsorbingIndoor --> UpdatingRisk
        UpdatingRisk --> Resting
    }

    state AtWork {
        [*] --> Working
        Working --> AbsorbingIndoor : Every step
        AbsorbingIndoor --> UpdatingRisk
        UpdatingRisk --> Working
    }
```

---

## 5. Component Diagram - System Architecture

```mermaid
graph TB
    subgraph "GAMA Platform 2025_06"
        subgraph "Main Model: Cancer_Risk_Simulate_Modular.gaml"
            Global[Global Controller]
            Params[Global Parameters]
            Stats[Statistics Monitors]
        end

        subgraph "Species Modules"
            Infra[Infrastructure.gaml]
            Resident[Resident_WithRisk.gaml]
            Pollution[PollutionGrid.gaml]
        end

        subgraph "Base Classes"
            InfraBase[Infras_base.gaml]
            InhabitantBase[Inhabitant_base.gaml]
        end

        subgraph "GIS Data"
            Buildings[building_polygon.shp]
            Roads[highway_line.shp]
        end

        subgraph "Experiments"
            GUI[GUI Experiment]
            Batch[Batch Scenarios]
        end

        subgraph "Displays"
            PollutionMap[Pollution Map Display]
            Analysis[PM2.5 Analysis Display]
            RiskDist[Risk Distribution Display]
            Dashboard[Dashboard Display]
        end
    end

    Global --> Infra
    Global --> Resident
    Global --> Pollution

    Infra --> InfraBase
    Resident --> InhabitantBase

    Infra --> Buildings
    Infra --> Roads

    GUI --> Global
    Batch --> Global

    Stats --> PollutionMap
    Stats --> Analysis
    Stats --> RiskDist
    Stats --> Dashboard

    Resident --> Pollution
    Resident --> Infra
```

---

## 6. Deployment Diagram - Runtime Environment

```mermaid
graph TB
    subgraph "User's Computer"
        subgraph "GAMA Platform Runtime"
            Engine[GAMA Simulation Engine]
            Visualizer[3D/2D Visualizer]
            Console[Console Output]
        end

        subgraph "Workspace"
            Project[CancerRiskSimulation Project]
            Models[*.gaml Files]
            Data[includes/ folder]
        end

        subgraph "System Resources"
            CPU[CPU - Agent Scheduling]
            Memory[RAM - 3000-8000 Agents]
            GPU[GPU - 3D Rendering]
        end
    end

    Project --> Models
    Project --> Data
    Engine --> Models
    Engine --> CPU
    Engine --> Memory
    Visualizer --> GPU
    Engine --> Visualizer
    Engine --> Console
```

---

## 7. Use Case Diagram - User Interactions

```mermaid
graph LR
    subgraph Actors
        Researcher[Researcher]
        Student[Student]
        PolicyMaker[Policy Maker]
    end

    subgraph "Cancer Risk Simulation System"
        Run[Run Simulation]
        Adjust[Adjust Parameters]
        View[View Real-time Results]
        Export[Export Data]
        Compare[Compare Scenarios]
        Analyze[Analyze Risk Distribution]
    end

    Researcher --> Run
    Researcher --> Adjust
    Researcher --> View
    Researcher --> Export
    Researcher --> Compare

    Student --> Run
    Student --> View
    Student --> Analyze

    PolicyMaker --> Compare
    PolicyMaker --> Analyze
    PolicyMaker --> View

    Run --> View
    Adjust --> Run
    Compare --> Run
```

---

## 8. Object Diagram - Runtime Example (8 Hours Simulation)

```
┌─────────────────────────────────────────────────────────────┐
│                     Global Model State                       │
│  cycle: 480 (8 hours × 60 steps/hour)                       │
│  current_date: 14:00 (2 PM)                                  │
│  avg_pm25: 142.5 μg/m³                                       │
│  avg_risk_probability: 0.157 (15.7%)                         │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ resident#0   │    │ resident#1   │    │ resident#2   │
├──────────────┤    ├──────────────┤    ├──────────────┤
│ is_male: T   │    │ is_male: F   │    │ is_male: T   │
│ is_smoke: T  │    │ is_smoke: F  │    │ is_smoke: T  │
│ is_obese: F  │    │ is_obese: T  │    │ is_obese: F  │
│ is_wearmask:T│    │ is_wearmask:T│    │ is_wearmask:F│
├──────────────┤    ├──────────────┤    ├──────────────┤
│baseline: 0.9 │    │baseline: 0.6 │    │baseline: 0.9 │
│cum_risk: 3.2 │    │cum_risk: 2.1 │    │cum_risk: 4.7 │
│risk_prob:0.21│    │risk_prob:0.14│    │risk_prob:0.31│
├──────────────┤    ├──────────────┤    ├──────────────┤
│state: travel │    │state: travel │    │state: AtWork │
│location: Road│    │location: Road│    │location: Bldg│
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       │ emits_to          │ emits_to          │ inside
       ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│pollution#245 │    │pollution#312 │    │ building#42  │
├──────────────┤    ├──────────────┤    ├──────────────┤
│pm25_level:   │    │pm25_level:   │    │ type: work   │
│  187.3 μg/m³ │    │  201.5 μg/m³ │    │ capacity: 50 │
│color: #FF3E00│    │color: #FF1A00│    │ residents: 38│
│  (Red-Orange)│    │  (Deep Red)  │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
```

---

## 9. Interaction Diagram - PM2.5 Diffusion Process

```mermaid
sequenceDiagram
    participant Global
    participant Grid1 as pollution_grid[i,j]
    participant Grid2 as pollution_grid[i+1,j]
    participant Grid3 as pollution_grid[i-1,j]
    participant Grid4 as pollution_grid[i,j+1]
    participant Grid5 as pollution_grid[i,j-1]

    Note over Global: Hourly Trigger (current_date.hour changed)

    Global->>Grid1: Check pm25_level before diffusion
    Grid1-->>Global: pm25_level = 200.0 μg/m³

    Global->>Grid1: diffuse(var: pm25_level, proportion: 0.6)

    Note over Grid1: Diffusion Algorithm<br/>Share 60% to 8 neighbors<br/>Each neighbor gets 7.5%

    Grid1->>Grid2: Send 15.0 μg/m³ (7.5%)
    Grid1->>Grid3: Send 15.0 μg/m³ (7.5%)
    Grid1->>Grid4: Send 15.0 μg/m³ (7.5%)
    Grid1->>Grid5: Send 15.0 μg/m³ (7.5%)

    Note over Grid1: Retain 40% = 80.0 μg/m³

    Grid2-->>Grid1: Also sends back
    Grid3-->>Grid1: Also sends back
    Grid4-->>Grid1: Also sends back
    Grid5-->>Grid1: Also sends back

    Note over Grid1: After diffusion: pm25_level ≈ 150-180 μg/m³

    Grid1->>Grid1: hourly_decay()
    Note over Grid1: pm25_level *= 0.9<br/>(10% decay per hour)

    Grid1-->>Global: Final pm25_level ≈ 135-162 μg/m³
```

---

## 10. Package Diagram - Code Organization

```mermaid
graph TB
    subgraph "Project Root"
        subgraph "models/ Package"
            Main[Cancer_Risk_Simulate_Modular.gaml]

            subgraph "Species Package"
                Resident[Resident_WithRisk.gaml]
                Infra[Infrastructure.gaml]
                Grid[PollutionGrid.gaml]
            end

            subgraph "Base Package"
                InhabitantBase[Inhabitant_base.gaml]
                InfraBase[Infras_base.gaml]
            end
        end

        subgraph "includes/ Package"
            Buildings[building_polygon.shp + .dbf + .shx]
            Roads[highway_line.shp + .dbf + .shx]
        end

        subgraph "Documentation Package"
            README[README.md]
            PROJECT[PROJECT.md]
            PRESENTATION[PRESENTATION_OUTLINE.md]
            SPECIES[SPECIES_TABLES.md]
            UML[UML_DIAGRAMS.md]
        end
    end

    Main --> Resident
    Main --> Infra
    Main --> Grid

    Resident --> InhabitantBase
    Infra --> InfraBase

    Infra --> Buildings
    Infra --> Roads
```

---

## 11. Data Flow Diagram - Risk Calculation Pipeline

```mermaid
flowchart LR
    subgraph Input
        Personal[Personal Attributes:<br/>gender, smoke, obese,<br/>family_history, mask]
        Environment[Environmental Data:<br/>PM2.5 grid levels]
        Location[Location State:<br/>indoor/outdoor,<br/>building/road]
    end

    subgraph Processing
        Baseline[Calculate Baseline Risk:<br/>baseline_risk = Σ(risk_factors)]
        Exposure[Calculate PM Exposure:<br/>pm_dose = pm25 × theta × (1-mask)]
        Accumulation[Accumulate Risk:<br/>cumulative_risk += dose × omega_pm]
        Sigmoid[Apply Sigmoid Function:<br/>P = 1/(1+exp(-k(cum+base)+b))]
    end

    subgraph Output
        Risk[Risk Probability:<br/>0.0 - 1.0]
        Category[Risk Category:<br/>Low/Medium/High/VeryHigh]
        Color[Visualization:<br/>Green/Yellow/Orange/Red]
    end

    Personal --> Baseline
    Environment --> Exposure
    Location --> Exposure

    Baseline --> Sigmoid
    Exposure --> Accumulation
    Accumulation --> Sigmoid

    Sigmoid --> Risk
    Risk --> Category
    Risk --> Color
```

---

## How to Use These Diagrams in Your Presentation

### Slide Recommendations:

1. **Slide 4 (Architecture)**: Use **Component Diagram** (#5) - Shows overall system structure
2. **Slide 5 (Species Overview)**: Use **Class Diagram** (#1) - Shows all species and relationships
3. **Slide 6 (Simulation Flow)**: Use **Activity Diagram** (#3) - Shows resident daily cycle
4. **Slide 7 (Mathematical Model)**: Use **Data Flow Diagram** (#11) - Shows risk calculation pipeline
5. **Slide 11 (Live Demo)**: Use **Sequence Diagram** (#2) - Explain what happens during commute

### Printing Tips:

- Export as PNG/SVG using Mermaid Live Editor: https://mermaid.live/
- Use landscape orientation for wider diagrams
- Print Class Diagram on A3 paper if possible
- For the presentation, show 2-3 key diagrams maximum (don't overwhelm)

### Code Rendering:

These diagrams use **Mermaid** syntax which renders in:
- GitHub (automatic)
- VSCode (with Mermaid extension)
- PowerPoint (copy as image from Mermaid Live)
- GAMA Documentation (if exported as images)

### Quick Reference:

| Diagram Type | Best For | Complexity |
|--------------|----------|------------|
| Class (#1) | Species structure | ★★★★☆ |
| Sequence (#2) | Step-by-step flow | ★★★★★ |
| Activity (#3) | Daily routine | ★★★☆☆ |
| State (#4) | Resident states | ★★★☆☆ |
| Component (#5) | System overview | ★★☆☆☆ |
| Data Flow (#11) | Risk calculation | ★★★☆☆ |

**Recommendation for 15-min presentation**: Show Component (#5), Class (#1), and Data Flow (#11) only.
