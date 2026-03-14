# Octopus Optimization Algorithm (OOA) - Multi-Objective Version

## Overview
This is the multi-objective adaptation of the Octopus Optimization Algorithm (OOA), integrating non-dominated sorting and crowding distance mechanisms for Pareto-based optimization.

## Key Adaptations for Multi-Objective Optimization

### 1. Environmental Selection
- Uses non-dominated sorting to rank solutions
- Applies crowding distance for diversity maintenance
- Selects N best solutions based on Pareto dominance

### 2. Global Best Selection
- Randomly selects from first Pareto front
- Ensures diversity in guidance mechanism
- Prevents bias toward specific objectives

### 3. Head-Tentacle Exchange
- Based on Pareto dominance instead of fitness
- Tentacle replaces head if it dominates
- Maintains non-dominated solutions

### 4. Scout Mechanism
- Selects targets from different fronts:
  - Scout 1: Best (first front)
  - Scout 2: Worst (last front)
  - Others: Random fronts
- Replaces target if scout dominates

### 5. Population Reconstruction
- After environmental selection, octopus structure is rebuilt
- Ensures selected solutions are properly distributed
- Maintains algorithm structure throughout evolution

## Algorithm Flow

```
1. Initialize population and octopus structure
2. Perform environmental selection
3. Select global best from first front
4. While not terminated:
   a. Update tentacles (exploration/exploitation)
   b. Exchange heads with best tentacles
   c. Scout phase with dominance-based replacement
   d. Combine all solutions
   e. Environmental selection
   f. Update global best
   g. Reconstruct octopus structure
```

## Usage

```matlab
% Run on DTLZ2 (3 objectives)
platemo('algorithm',@OOA,'problem',@DTLZ2,'N',100,'maxFE',25000,'M',3)

% Run on ZDT1 (2 objectives)
platemo('algorithm',@OOA,'problem',@ZDT1,'N',100,'maxFE',25000)

% Run on DTLZ7 (5 objectives)
platemo('algorithm',@OOA,'problem',@DTLZ7,'N',200,'maxFE',50000,'M',5)
```

## Files
- `OOA.m`: Main multi-objective algorithm
- `EnvironmentalSelection.m`: Non-dominated sorting and crowding distance selection

## Advantages
- Maintains diversity through crowding distance
- Balances exploration and exploitation
- Effective for many-objective problems
- Adaptive population structure

## Comparison with Single-Objective Version
| Aspect | Single-Objective | Multi-Objective |
|--------|------------------|-----------------|
| Selection | Fitness-based | Pareto dominance |
| Global Best | Minimum fitness | Random from first front |
| Exchange | Fitness comparison | Dominance check |
| Diversity | Natural | Crowding distance |

## Reference
Octopus Optimization Algorithm (OOA), 2025
Adapted for multi-objective optimization using NSGA-II selection strategy
