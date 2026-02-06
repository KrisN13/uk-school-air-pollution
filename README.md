# Air Quality Analysis Around English Schools

An interactive data analytics project to optimize pollution intervention funding across 24,049 schools in England.

## Overview

This project uses spatial analytics and cost-benefit modeling to help educational policymakers allocate limited budgets for air quality interventions. By combining pollution monitoring data with school locations and deprivation indices, it identifies which schools and interventions provide the highest return on investment for protecting children's health.

**Live Dashboard:** [View on Tableau Public](https://public.tableau.com/app/profile/kris.noon/viz/Air_Quality_Analysis_Around_English_Schools/Dashboard1)

## Problem Statement

With over 24,000 schools across England exposed to varying levels of air pollution and a potential £3.2 billion needed for interventions, how do we prioritize funding to maximize impact?

## Data Sources

- **OpenAQ:** PM2.5 and NO₂ pollution readings (2022-2025)
- **UK Government:** School locations, enrollment data
- **UK Indices of Deprivation 2025:** Local authority deprivation metrics

## Methodology

### Data Processing (PostgreSQL + PostGIS)
- Spatial matching of schools to nearest monitoring stations
- Aggregated pollution exposure metrics over time
- Created exposure categories (Very High / High / Moderate / Low)
- Standardised school identifiers and cleaned missing values

### ROI Analysis
- Researched costs for 8 intervention types (air filtration, green barriers, traffic calming, etc.)
- Calculated cost-per-pupil-protected for each intervention type
- Modeled effectiveness by exposure level using real-world case studies

### Visualization (Tableau Public)
- Interactive budget simulator (£500k - £50M)
- Intervention priority matrix (heat map by exposure level)
- Geographic clustering map
- Cumulative impact curves

## Key Findings

- **Classroom air filtration** delivers highest ROI: 185 pupils protected per £1,000 spent
- **Whole-school systems** cost 10x more per pupil protected (£45,000 vs. £4,500)
- **Green barriers** show minimal ROI despite £10,000 cost
- **Geographic targeting** improves efficiency 3-4x vs. even distribution
- **London** accounts for 85% more ROI potential than next-highest authority

## Tech Stack

- **Database:** PostgreSQL 16 with PostGIS extension
- **Spatial Analytics:** PostGIS ST_Distance, geometry indexing
- **Visualization:** Tableau Public
- **Languages:** SQL, JavaScript (for presentation generation)

## Impact

Enables evidence-based allocation of £3.2B in potential funding:
- £5M strategically allocated protects ~6,250 pupils
- Same budget with even distribution protects only 1,500-2,000 pupils
- Identifies top 1,000 priority schools for immediate intervention

## Limitations & Future Work

- **Temporal granularity:** Averaged 2022-2025 data; should separate seasonal patterns
- **Distance weighting:** Used nearest station; should implement inverse distance weighting
- **Equity adjustment:** ROI treats all pupils equally; should add deprivation multipliers
- **Health validation:** Should validate against NHS respiratory illness data

## Author

Kris Noon
Passionate about using data analytics for environmental and social impact

## License

Data sources are publicly available. Analysis methodology and visualizations © 2026 Kris Noon