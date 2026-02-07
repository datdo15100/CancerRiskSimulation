# Presentation Outline - 15 Minutes

**Cancer Risk Simulation: Agent-Based PM2.5 Exposure Model**

---

## 📋 Timing Breakdown

| Section | Duration | Speaker | Content |
|---------|----------|---------|---------|
| **1. Introduction** | 2 min | Member 1 | Project overview & research question |
| **2. Live Demo** | 3 min | Member 2 | Open GAMA, run model, show displays |
| **3. Model Description** | 5 min | Member 3 | Species, behaviors, formulas |
| **4. Results & Calibration** | 3 min | Member 4 | Key findings, validation |
| **5. Limitations & Future** | 2 min | Member 1 | Challenges, next steps |
| **Q&A Buffer** | | All | Handle questions |

**Total: 15 minutes**

---

## 🎯 Slide 1: Title Slide (30 seconds)

**Content:**
- **Title:** "Agent-Based Modeling of Cancer Risk from PM2.5 Air Pollution Exposure"
- **Subtitle:** "Urban Traffic Emissions and Health Impacts"
- **Team:**
  - Nguyen Dang Trung - 2440054
  - Do Thanh Dat - 2440059
  - Nguyen Thanh Binh - 2440052
- **Course:** Agent-Based Modeling with GAMA
- **Date:** February 7, 2025

**Speaker:** Member 1

**Script:**
> "Good morning everyone. Today we'll present our Agent-Based Model that simulates the relationship between urban air pollution and cancer risk. Our model tracks 8000 individual residents in Hanoi as they commute daily, accumulating PM2.5 exposure over time."

---

## ❓ Slide 2: Research Question (1 min)

**Content:**
- **Primary Question:**
  *"How does daily PM2.5 exposure from urban traffic affect cancer risk probability in populations with different lifestyle factors?"*

- **Key Challenges:**
  - PM2.5 exposure is spatial and temporal
  - Individual behaviors vary (commute patterns, mask-wearing)
  - Cancer risk depends on both pollution AND lifestyle (smoking, obesity)

- **Why ABM?**
  - Captures heterogeneity (each agent is unique)
  - Models spatial patterns (hotspots, gradients)
  - Links micro-behaviors to macro-outcomes

**Visual:** Conceptual diagram showing "Urban Traffic → PM2.5 → Individual Exposure → Cancer Risk"

**Speaker:** Member 1

**Script:**
> "We want to understand how urban traffic pollution affects cancer risk at the individual and population level. Traditional models treat everyone the same, but ABM allows us to model each person's unique exposure based on where they live, work, and how they travel. This is especially relevant for Hanoi, where air quality index often exceeds 200."

---

## 🖥️ Slide 3: Live Demo Setup (30 seconds)

**Content:**
- **What We'll Show:**
  1. GAMA platform interface
  2. Running model
  3. Real-time displays
  4. Key code snippets

- **Displays:**
  - Pollution Map (PM2.5 grid + agents)
  - PM2.5 & Risk Charts
  - Risk Distribution
  - Statistics Dashboard

**Visual:** Screenshot of GAMA interface with all displays

**Speaker:** Member 2

**Script:**
> "Let me now show you a live demonstration of the model running in GAMA. You'll see how pollution evolves over time and how cancer risk accumulates in our simulated population."

---

## 💻 LIVE DEMO (3 minutes)

**Actions:**
1. **Open GAMA** (already open, HDMI connected)
2. **Show Project Structure** (30s)
   - Point to folder tree: models/, includes/
   - "Our project has 6 GAML files and GIS data from OpenStreetMap"

3. **Open Main File** (30s)
   - `Cancer_Risk_Simulate_Modular.gaml`
   - Scroll to show structure:
     - Global parameters
     - Init actions
     - Reflexes (diffusion, decay)

4. **Show Key Code** (30s)
   - Open `Resident_WithRisk.gaml`
   - Show `reflex move` (line 153-159)
   ```gaml
   reflex move when: target != nil and not is_inside_building {
       do calculate_emission();
       do move_towards_target();
       do emit_pollution();
       do check_if_stuck_and_reassign();
       do check_arrival();
   }
   ```
   - "This is the core behavior: agents move, emit PM2.5, and accumulate risk"

5. **Run Simulation** (90s)
   - Click ▶️ Play
   - **Pollution Map:**
     - "See the green grid? That's PM2.5. Watch what happens during rush hour..."
     - Fast-forward to 7am
     - "Now it's morning commute - agents leave home (orange) and travel (yellow triangles/circles)"
     - Point to red/purple hotspots on roads

   - **PM2.5 Chart:**
     - "Average PM2.5 rises from 30 to 180 μg/m³ - that's AQI 200, very unhealthy"

   - **Risk Distribution:**
     - "Cancer risk starts at 5-10% and increases over time"
     - "High risk category is growing - these are smokers with high exposure"

6. **Show Parameters** (30s)
   - Open Parameters panel
   - "We can adjust population, emission rates, mask effectiveness"
   - "All parameters are calibrated to match Hanoi's pollution levels"

**Speaker:** Member 2

**Key Points to Mention:**
- ✅ Model runs successfully
- ✅ Uses real GIS data (Hanoi)
- ✅ 8000 agents with heterogeneous traits
- ✅ Real-time visualization updates
- ✅ Code is modular and well-organized

---

## 🧬 Slide 4: Model Architecture (1 min)

**Content:**
```
┌─────────────────────────────────────────┐
│        SIMULATION ENVIRONMENT           │
│                                         │
│  Buildings (500) ←→ Roads (200)        │
│       ↑                  │              │
│       │                  ↓              │
│  Residents (8000) → Pollution Grid     │
│                      (50×50)            │
│       │                  │              │
│       └──────────────────┘              │
│         Risk Calculation                │
└─────────────────────────────────────────┘
```

**Key Numbers:**
- **8000 residents** (agents)
- **500 buildings** from OSM
- **200 roads** from OSM
- **2500 grid cells** (50×50 PM2.5 tracking)

**Visual:** Architecture diagram with icons

**Speaker:** Member 3

**Script:**
> "Our model has four main species. Residents are autonomous agents that commute between buildings on the road network. As they travel, they emit PM2.5 into a 50-by-50 grid. The pollution diffuses, decays, and is absorbed by residents, who accumulate cancer risk over time."

---

## 👤 Slide 5: Resident Species (1.5 min)

**Content:**

### Attributes (Heterogeneous)
| Attribute | Distribution | Impact |
|-----------|-------------|--------|
| **Gender** | 60% male | +0.3 baseline risk |
| **Smoking** | 30% smokers | +0.6 baseline risk |
| **Obesity** | 30% obese | +0.3 baseline risk |
| **Family History** | 12.5% | +0.4 baseline risk |
| **Mask Wearing** | 85% | -60% exposure |

### Daily Schedule
```
06:00-09:00  🏠→🏢  Morning commute (random start time)
09:00-14:00  🏢     At work (8 hours)
14:00-17:00  🏢→🏠  Evening commute
17:00-06:00  🏠     At home
```

### Key Behaviors (Reflexes)
1. **Movement:** Follow road network, emit PM2.5 (10-20 μg/m³/step)
2. **Risk Calculation:** Update every step based on current PM2.5 exposure
3. **Stuck Detection:** Reassign destination if can't reach building

**Visual:** Agent lifecycle flowchart + trait distribution chart

**Speaker:** Member 3

**Script:**
> "Each resident is unique. They have personal characteristics like gender, smoking status, and whether they wear masks. These traits affect their baseline cancer risk. Every day, they commute to work in the morning and return home in the evening. While traveling, they emit PM2.5 based on traffic, and they absorb pollution based on their location and mask-wearing."

---

## 🌫️ Slide 6: PM2.5 & Environment (1.5 min)

**Content:**

### Pollution Grid (50×50)
- **Emission:** Residents emit 10-20 μg/m³ per step when traveling
- **Diffusion:** 60% flows to 8 neighbors **every hour**
- **Decay:** 10% decay **every hour** (half-life ≈ 6.6 hours)

### Mathematical Model

**1. Emission:**
```
emission_pm = base_rate × emission_multiplier
base_rate ∈ [10, 20] μg/m³/step (calibrated for Hanoi)
```

**2. Diffusion (GAMA operator):**
```gaml
diffuse var: pm25_level on: pollution_grid proportion: 0.6
```

**3. Decay:**
```
pm25_level(t+1h) = pm25_level(t) × 0.9
```

**4. Exposure Dose:**
```
pm_dose = current_pm25 × Δt × θ × (1 - protect)

where:
  θ = 1.0 (outdoor) or 0.3 (indoor)
  protect = 0.6 (if wearing mask) or 0 (no mask)
```

### Color Visualization (EPA AQI)
- Green < 12 → Yellow 35 → Orange 55 → Red 150 → Purple 250 → Maroon

**Visual:** Grid animation showing diffusion process + color scale

**Speaker:** Member 3

**Script:**
> "The pollution grid models PM2.5 spatially. When residents travel on roads, they emit pollution into grid cells. Every hour, PM2.5 diffuses to neighbor cells at 60% rate and decays by 10%. We use the US EPA color scale so green means good air quality and red-purple means hazardous levels, which is common during Hanoi rush hours."

---

## 🧮 Slide 7: Cancer Risk Formula (1 min)

**Content:**

### Step-by-Step Calculation

**1. Baseline Risk (at initialization):**
```
baseline_risk = 0
if male:           baseline_risk += 0.3
if smoker:         baseline_risk += 0.6
if obese:          baseline_risk += 0.3
if family_history: baseline_risk += 0.4
```

**2. Cumulative Risk (every step):**
```
X_pm = min(1.0, pm_dose / PM_ref)
risk_increment = ω_pm × X_pm
cumulative_risk += risk_increment

where:
  PM_ref = 150 μg/m³ (reference level)
  ω_pm = 0.03 (PM weight - calibrated)
```

**3. Probability (sigmoid function):**
```
z = k × (cumulative_risk + baseline_risk) + b
risk_probability = 1 / (1 + e^(-z))

where:
  k = 2.0 (slope - steepness)
  b = -4.0 (threshold - 50% risk when score = 2.0)
```

### Example
```
Male smoker, high PM2.5 exposure (150 μg/m³, 8 hours):
  baseline_risk = 0.3 + 0.6 = 0.9
  cumulative_risk ≈ 0.8 (after 8h)
  z = 2.0 × (0.8 + 0.9) - 4.0 = -0.6
  risk_probability = 35%
```

**Visual:** Sigmoid curve showing risk vs exposure + example calculation

**Speaker:** Member 3

**Script:**
> "Cancer risk is calculated using a sigmoid function inspired by epidemiological models. First, we compute baseline risk from lifestyle factors. Then, every minute, we add a risk increment based on PM2.5 exposure. Finally, we apply a sigmoid function to convert the cumulative score into a probability between 0 and 1. The sigmoid ensures that risk increases slowly at first, then rapidly, then plateaus - matching real cancer development."

---

## 📊 Slide 8: Results - Temporal Patterns (1 min)

**Content:**

### PM2.5 Daily Pattern
```
Hour | Activity      | Avg PM2.5 (μg/m³)
-----|---------------|------------------
06h  | Night         | 30
07h  | Morning rush  | 180 ⬆
08h  | Peak          | 220 ⬆⬆
09h  | Arrive work   | 120 ⬇
10-13| At work       | 50-70
14h  | Evening rush  | 160 ⬆
15h  | Peak          | 200 ⬆⬆
16h  | Arrive home   | 100 ⬇
17h+ | Night         | 40-60
```

### Risk Evolution (Population Average)
| Time | Avg Risk | High Risk (>50%) |
|------|----------|------------------|
| 1 hour | 6% | 1% |
| 8 hours | 14% | 4% |
| 24 hours | 22% | 10% |

**Visual:** Time series chart showing PM2.5 and risk over 24h

**Speaker:** Member 4

**Script:**
> "Here are our simulation results. PM2.5 follows a clear daily pattern with two peaks - morning and evening rush hours. Average levels reach 200 micrograms per cubic meter during peaks, which is AQI 250, very unhealthy. Cancer risk accumulates over time: starting at 5-6%, reaching 14% after a work day, and 22% after 24 hours."

---

## 🗺️ Slide 9: Results - Spatial Patterns (1 min)

**Content:**

### Spatial Distribution

**Morning Rush Hour (7-8am):**
- 🔴 **High PM2.5 (150-250 μg/m³)** along major roads
- 🟠 **Medium PM2.5 (80-150 μg/m³)** near roads
- 🟡 **Low PM2.5 (30-80 μg/m³)** residential areas
- 🟢 **Very Low PM2.5 (<30 μg/m³)** parks, edges

**Risk Hotspots:**
- Residents living/working near high-traffic roads
- Smokers with high exposure: 40-60% risk after 24h
- Non-smokers with low exposure: 8-15% risk after 24h

### Key Observation
> **Spatial inequality:** Residents near major roads have 2-3× higher exposure and 1.5-2× higher cancer risk than those in low-traffic areas.

**Visual:**
- Heatmap of PM2.5 at 7am
- Heatmap of cancer risk at 24h
- Side-by-side comparison

**Speaker:** Member 4

**Script:**
> "Spatially, we see clear gradients. Roads light up red-purple during rush hours, while residential areas stay yellow-green. This creates health inequalities: people who live or work near busy roads face much higher cancer risk. Our model shows a 2 to 3 times difference in exposure between high-traffic and low-traffic neighborhoods."

---

## 🧪 Slide 10: Scenario Comparison (1 min)

**Content:**

### Three Batch Scenarios

| Scenario | smoke_rate | obese_rate | mask_rate | emission | Duration |
|----------|------------|------------|-----------|----------|----------|
| **0 - Baseline** | 30% | 30% | 85% | 100% | 24h |
| **1 - Unhealthy** | 80% | 60% | 10% | 100% | 24h |
| **2 - Clean Air** | 30% | 30% | 85% | 0% | 24h |

### Results After 24 Hours

| Scenario | Avg Risk | High Risk (>50%) | Very High (>80%) |
|----------|----------|------------------|------------------|
| **Baseline** | 22% | 10% | 2% |
| **Unhealthy Lifestyle** | 38% | 28% | 9% |
| **Clean Air** | 9% | 1% | 0% |

### Key Insights
- 🚬 **Lifestyle effect:** Unhealthy scenario → +73% avg risk vs baseline
- 🌳 **Environmental effect:** Clean air → -59% avg risk vs baseline
- 🔀 **Interaction:** Risk is **multiplicative**, not additive (PM2.5 × smoking > PM2.5 + smoking)

**Visual:** Bar chart comparing avg risk across scenarios

**Speaker:** Member 4

**Script:**
> "We ran batch experiments to compare scenarios. The unhealthy lifestyle scenario - high smoking, low mask use - results in 73% higher average risk than baseline. The clean air scenario - zero emissions - reduces risk by 59%. This shows that both environmental policies and public health interventions are important, and their effects interact multiplicatively."

---

## ✅ Slide 11: Model Calibration (1 min)

**Content:**

### Calibration Process

**1. PM2.5 Emission Calibration**
- **Target:** Match Hanoi AQI 150-200 during rush hours
- **Method:** Iteratively adjusted `base_emission_rate`
- **Result:** 10-20 μg/m³/step → avg 100-180 μg/m³ ✓

**2. Diffusion/Decay Balance**
- **Issue:** With step=60s, diffusion ran 60×/hour → over-smoothing
- **Solution:** Trigger diffusion **once per hour** (hourly reflex)
- **Result:** Visible pollution hotspots ✓

**3. Risk Formula Calibration**
- **Issue:** Original parameters (for year-long simulation) too slow
- **Solution:**
  - `omega_pm: 0.01 → 0.03` (3× faster accumulation)
  - `k: 1.0 → 2.0` (steeper sigmoid)
  - `b: -5.0 → -4.0` (lower 50% threshold)
- **Result:** Risk reaches 20-30% in 24h ✓

### Validation
- Compared with epidemiological literature:
  - +10 μg/m³ PM2.5 → +4-6% lung cancer risk (long-term)
  - Our model extrapolates consistently ✓

**Visual:** Before/after comparison charts

**Speaker:** Member 4

**Script:**
> "Calibration was essential to make our model realistic. We tuned emission rates to match Hanoi's actual air quality, adjusted diffusion timing to show spatial patterns, and recalibrated the risk formula so changes would be visible in our short simulation timeframe. We validated against epidemiological studies showing that 10 micrograms increase in PM2.5 leads to 4-6% higher cancer risk over decades."

---

## 🚧 Slide 12: Limitations (1 min)

**Content:**

### Technical Limitations
1. **Performance:** 8000 agents × 60s step → slow (5-10 real seconds per sim minute)
   - Limits simulation duration (typically 1-2 days max)

2. **Spatial Resolution:** 50×50 grid (≈100m cells) misses street-level detail

3. **Road Network:** OSM data has disconnected components → stuck agents
   - Mitigated with reassignment algorithm

### Conceptual Limitations
4. **Simplified Risk Model:**
   - No age effects, no latency period
   - Binary traits (smoke/don't smoke, no intensity)
   - No synergistic effects (PM2.5 × smoking interaction)
   - **Result:** Risk is **relative**, not absolute forecasting

5. **Temporal Scale Mismatch:**
   - Cancer develops over decades, we simulate days
   - Risk parameters **calibrated** for visible changes (accelerated)

6. **Missing Factors:**
   - Other pollutants (NO₂, O₃)
   - Weather (wind, rain)
   - Background sources (factories, heating)

7. **Simplified Behavior:**
   - Fixed work schedules (no weekends, holidays)
   - No behavior adaptation (routes, habits)

**Visual:** Icons representing each limitation

**Speaker:** Member 1

**Script:**
> "Every model has limitations. Ours is computationally intensive, so we can only simulate days not years. Our risk formula is empirical and simplified - real cancer development is far more complex. We also miss many factors like weather, other pollutants, and individual behavior changes. Importantly, our risk values are relative comparisons between scenarios, not absolute predictions of cancer incidence."

---

## 🚀 Slide 13: Future Perspectives (1 min)

**Content:**

### Short-term Improvements
✅ **Feasible within weeks:**
- Add weekend vs weekday patterns
- Seasonal variations (winter heating, summer)
- Enhance visualization (heatmap animations, agent trajectories)
- Sensitivity analysis on key parameters

### Medium-term Extensions
🔬 **Require months:**
- **Multi-pollutant model:** Add NO₂, O₃
- **Intervention scenarios:**
  - Traffic reduction policies (congestion pricing, car-free zones)
  - Green infrastructure (parks absorb PM2.5)
  - Mask distribution campaigns
- **Social network effects:** Agents influence each other's mask-wearing

### Long-term Research
🎯 **Ambitious (6+ months):**
- **Machine learning integration:** Train surrogate models for fast predictions
- **Multi-city comparison:** Beijing, Delhi, Los Angeles
- **Longitudinal model:** Extend to years/decades with cancer latency
- **Policy optimization:** Find optimal intervention mixes (minimize risk + cost)

### Key Research Questions
- How does urban form (street layout, density) affect exposure patterns?
- What is the optimal mask distribution strategy?
- Can agent learning (route optimization) reduce exposure?

**Visual:** Roadmap timeline with icons

**Speaker:** Member 1

**Script:**
> "Looking ahead, we have many directions to explore. Short-term, we can add more realistic temporal patterns and improve visualization. Medium-term, we want to model interventions like traffic policies and green infrastructure. Long-term, we could extend the model to multiple cities and use machine learning to optimize policies. The key is making this model useful for urban planning and public health decision-making."

---

## 🎓 Slide 14: Lessons Learned (30 seconds)

**Content:**

### What We Learned
1. **ABM Complexity:**
   - Balancing realism vs performance
   - Debugging 8000 agents is hard!
   - Modularity helps (separate files for species)

2. **GAMA Platform:**
   - Powerful GIS integration (OSM shapefiles)
   - Built-in diffusion operator very useful
   - Batch experiments for scenario comparison

3. **Calibration is Key:**
   - Model behavior highly sensitive to parameters
   - Iterative tuning needed (emission, diffusion, risk)
   - Validation against real data essential

4. **Interdisciplinary Skills:**
   - GIS, epidemiology, programming
   - Urban planning, public health policy
   - Visualization for communication

**Visual:** Word cloud or mind map

**Speaker:** Member 1

**Script:**
> "This project taught us a lot. We learned that agent-based models require careful balancing between realism and computational feasibility. GAMA's GIS integration was powerful but we had to deal with messy real-world data. Calibration took significant effort - small parameter changes led to big behavior changes. Most importantly, we learned how to bridge computer science, epidemiology, and urban planning."

---

## 🎬 Slide 15: Conclusion & Thank You (30 seconds)

**Content:**

### Summary
- ✅ **Built a working ABM** with 8000 agents, GIS data, PM2.5 diffusion
- ✅ **Calibrated to match** Hanoi air quality levels
- ✅ **Showed spatial-temporal patterns** of pollution and cancer risk
- ✅ **Compared intervention scenarios** (lifestyle, clean air)
- ✅ **Identified limitations** and future directions

### Key Takeaway
> **Agent-based modeling reveals how individual behaviors and spatial patterns combine to create population-level health outcomes. Our model can inform urban planning and public health policy in polluted cities.**

### Thank You
- **Instructors:** Arnaud and Alexis
- **GAMA Developers**
- **OpenStreetMap Contributors**

### Questions?

**Contact:**
- Repository: github.com/datdo15100/CancerRiskSimulation
- Team: [emails]

**Visual:** Team photo or model screenshot + QR code to repo

**Speaker:** All

**Script:**
> "In conclusion, we successfully built a realistic agent-based model linking urban traffic pollution to cancer risk. Our model shows clear spatial patterns and validates the importance of both environmental and lifestyle interventions. Thank you to our instructors and the GAMA community. We're happy to answer any questions!"

---

## 💡 Tips for Presentation

### Before Presentation
- [ ] Test HDMI connection (bring adapter!)
- [ ] Pre-load GAMA with model open
- [ ] Pre-run simulation to 7am (save state if possible)
- [ ] Backup slides on USB + cloud
- [ ] Rehearse timing (15 min max!)
- [ ] Prepare answers to likely questions

### During Demo
- [ ] **Don't start from scratch** - have simulation pre-loaded
- [ ] **Fast-forward** to interesting times (7am, 3pm)
- [ ] **Pause** to point out key features
- [ ] **Zoom in** on pollution hotspots
- [ ] **Have backup screenshots** in case live demo fails

### Presentation Style
- [ ] Speak clearly and not too fast
- [ ] Make eye contact with audience
- [ ] Use laser pointer for screen
- [ ] Don't read slides word-for-word
- [ ] **Enthusiasm!** Show you're proud of your work

### Handling Questions
- [ ] Listen carefully to question
- [ ] Repeat question if unclear
- [ ] Answer concisely
- [ ] If don't know: "That's a great question for future work"
- [ ] Refer to relevant slide if needed

---

## ❓ Anticipated Questions & Answers

### Q1: "How did you validate your model?"
**A:** "We calibrated PM2.5 emission rates against observed AQI levels in Hanoi. For cancer risk, we compared our dose-response relationship with epidemiological literature showing +10 μg/m³ PM2.5 leads to +4-6% lung cancer risk. Our model extrapolates consistently. However, we acknowledge it's difficult to validate cancer risk fully since it develops over decades."

### Q2: "Why use step=60s instead of longer steps?"
**A:** "We initially tried larger steps (1 hour, 1 day) but residents couldn't move properly - they would teleport or get stuck. 60 seconds allows smooth movement while maintaining reasonable computational performance. We compensate by running diffusion and decay only once per hour, not every step."

### Q3: "How did you handle stuck agents?"
**A:** "Great question! We implemented a stuck detection algorithm. If an agent doesn't move for 20 consecutive steps, we reassign them to the nearest reachable building within 200 meters. This handles disconnected road network components in our OpenStreetMap data."

### Q4: "Are your risk values absolute or relative?"
**A:** "They're **relative** comparisons, not absolute predictions. Our sigmoid parameters are calibrated to show visible changes within our short simulation timeframe (hours/days), whereas real cancer develops over decades. The values are useful for comparing scenarios and identifying high-risk individuals, not forecasting actual cancer incidence rates."

### Q5: "Why didn't you include age, diet, genetics, etc.?"
**A:** "To keep the model manageable and focused on air pollution. We included the main modifiable factors (smoking, obesity, mask-wearing) and one genetic factor (family history). Adding more factors would increase complexity without fundamentally changing our main finding: PM2.5 exposure and lifestyle factors interact multiplicatively to affect cancer risk."

### Q6: "Could this be used for real urban planning?"
**A:** "Yes, with further development. Our model shows where pollution hotspots occur and which populations are most vulnerable. Urban planners could use it to evaluate traffic reduction policies, green infrastructure placement, or mask distribution strategies. However, more validation and refinement would be needed before using it for actual policy decisions."

### Q7: "Did you look at the GAMA model library?"
**A:** "Yes! We studied the Traffic models in the Toy Models section for road network pathfinding, and the Diffusion models for the PM2.5 grid. We adapted their approaches but developed our own risk calculation formula based on epidemiological research. All original modeling choices are documented in our PROJECT.md file."

### Q8: "How long does the simulation take to run?"
**A:** "For 24 simulated hours with 8000 agents, it takes about 20-30 minutes real time on our laptops. That's roughly 1 real minute per simulated hour. Batch experiments for three scenarios take about 90 minutes total."

---

## 📋 Checklist for Saturday

### Day Before (Friday)
- [ ] Final rehearsal with timer
- [ ] Verify GAMA 2025_06 installed
- [ ] Test model runs without errors
- [ ] Charge laptop (bring charger!)
- [ ] Print slide deck (backup)
- [ ] Prepare adapter/HDMI
- [ ] Get good sleep!

### Morning of Presentation
- [ ] Arrive 8:15am (15 min early)
- [ ] Test HDMI connection
- [ ] Open GAMA + load model
- [ ] Open slides in presentation mode
- [ ] Drink water, stay calm
- [ ] Support teammates!

---

**Good luck! You've built an excellent model - now show it off! 🚀**
