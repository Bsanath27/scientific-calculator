# Phase 3: Advanced Numeric Tools - Functional Test Cases

Copy and paste the inputs below into the respective tool panels to verify functionality.

## 1. Matrix Tool (Matrix Operations)

### Test 1: Matrix Addition [A + B]
**Input Matrix A:**
2 4
6 8

**Input Matrix B:**
1 2
3 4

**Select Operation:** `Add`
**Expected Result:**
[ 3.0000  6.0000 ]
[ 9.0000  12.0000 ]

---

### Test 2: Matrix Multiplication [A × B]
**Input Matrix A:**
1 2 3
4 5 6

**Input Matrix B:**
7 8
9 10
11 12

**Select Operation:** `Multiply`
**Expected Result:**
[ 58.0000  64.0000 ]
[ 139.0000  154.0000 ]

---

### Test 3: Determinant (Square Matrix)
**Input Matrix A:**
6 1 1
4 -2 5
2 8 7

**Select Operation:** `Determinant`
**Expected Result:** `-306`

---

### Test 4: Inverse
**Input Matrix A:**
4 7
2 6

**Select Operation:** `Inverse`
**Expected Result:**
[ 0.6000  -0.7000 ]
[ -0.2000  0.4000 ]

---

### Test 5: Eigenvalues
**Input Matrix A:**
2 1
1 2

**Select Operation:** `Eigenvalues`
**Expected Result:** `1.000000`\n`3.000000` (Order may vary)

---

## 2. Vector Tool (Vector Operations)

### Test 1: Dot Product (Orthogonal)
**Vector A:** `1 0 0`
**Vector B:** `0 1 0`
**Select Operation:** `Dot Product`
**Expected Result:** `0`

### Test 2: Dot Product (Parallel)
**Vector A:** `1 2 3`
**Vector B:** `4 5 6`
**Select Operation:** `Dot Product`
**Expected Result:** `32`

### Test 3: Cross Product
**Vector A:** `1 0 0`
**Vector B:** `0 1 0`
**Select Operation:** `Cross Product`
**Expected Result:** `[ 0.000000  0.000000  1.000000 ]`

### Test 4: L2 Norm (Magnitude)
**Vector A:** `3 4`
**Select Operation:** `Norm`
**Expected Result:** `5`

### Test 5: Normalize
**Vector A:** `3 4`
**Select Operation:** `Normalize`
**Expected Result:** `[ 0.600000  0.800000 ]`

---

## 3. Statistics Tool

### Test 1: Basic Descriptive Stats
**Data X:** `1 2 3 4 5 6 7 8 9 10`
**Select Operation:** `Mean`
**Expected Result:** `5.5`

**Select Operation:** `Median`
**Expected Result:** `5.5`

**Select Operation:** `Std Dev`
**Expected Result:** `3.027650` (Population SD)

### Test 2: Correlation & Regression
**Data X:** `1 2 3`
**Data Y:** `2 4 6`

**Select Operation:** `Correlation`
**Expected Result:** `1` (Perfect positive correlation)

**Select Operation:** `Linear Regression`
**Expected Result:** `y = 2.000000x + 0.000000  (R² = 1.000000)`

### Test 3: Moving Average
**Data X:** `1 2 3 4 5`
**Window Size:** `3`
**Select Operation:** `Moving Average`
**Expected Result:** `2.0000  3.0000  4.0000`

---

## 4. Graph Tool

### Test 1: Single Function Plot
**Expression:** `sin(x)`
**x Min:** `-3.14`
**x Max:** `3.14`
**Points:** `100`
**Click:** `Plot`
**Check:** Sine wave curve from -π to +π.

### Test 2: Multi-Function Overlay
**Step 1:** Enter `x^2`, Click `Add`
**Step 2:** Enter `x`, Click `Add`
**Step 3:** Click `Plot All`
**Check:** Parabola (blue) and line (red) on same chart.

### Test 3: Complex Function
**Expression:** `sin(x) * cos(x) + x/2`
**Click:** `Plot`
**Check:** Complex wave pattern, execution time < 5ms approx.

---

## 5. Units Tool

### Test 1: Length
**Category:** `Length`
**Value:** `1`
**From:** `km`
**To:** `m`
**Expected Result:** `1000.0 m`

### Test 2: Temperature
**Category:** `Temperature`
**Value:** `100`
**From:** `C`
**To:** `F`
**Expected Result:** `212.0 F`

### Test 3: Time
**Category:** `Time`
**Value:** `1`
**From:** `day`
**To:** `s`
**Expected Result:** `86400.0 s`
