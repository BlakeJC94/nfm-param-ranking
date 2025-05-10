NFM Parameter ranking
=====================

Random forest approach to ranking parameter importance in a neural field model,
adapted from Ferrat et al. 2018 \[0\].

This is a project that I worked on in 2018 during my time between University of
Exeter and University of Birmingham. The initial version of this project was a
random collection of scripts that generated a parameter space in MATLAB, solved
equations in Julia, and implemented the random forest in R.

Revisiting this in 2024/2025, I'm aiming to write this in pure Julia with a
clearer project structure

Usage
-----

``` {.bash}
$ julia run.jl
```
Results
-------

```
steady_state
------------
  G       1.0
  r_AB    0.7179
  B       0.4704
  r_ab    0.1554
  a       0.1375
  A       0.0981
  c       0.0933
  v_0     0.0137
  r       0.0098
  b       0.0073
  e_0     0.0032
  P       0.0014
  g       0.0009

seizure
-------
  b       1.0
  r_ab    0.7551
  c       0.1853
  e_0     0.1751
  A       0.1366
  B       0.0836
  g       0.0603
  G       0.0387
  r_AB    0.0235
  a       0.0115
  r       0.0038
  P       0.0
  v_0     0.0

frequency
---------
  b       1.0
  r_ab    0.5939
  c       0.0373
  r_AB    0.0297
  B       0.0245
  a       0.0203
  e_0     0.0188
  A       0.0087
  G       0.0041
  r       0.002
  g       0.0018
  P       0.0001
  v_0     0.0

amplitude
---------
  c       1.0
  e_0     0.8714
  G       0.4605
  b       0.1273
  B       0.1124
  r_ab    0.0592
  v_0     0.0547
  A       0.0255
  r_AB    0.0198
  r       0.0065
  g       0.0017
  P       0.0
  a       0.0
```

References
----------

0.  Ferrat, L.A., Goodfellow, M. and Terry, J.R., 2018. Classifying dynamic transitions in high
    dimensional neural mass models: A random forest approach. PLoS computational biology, 14(3),
    p.e1006009.
