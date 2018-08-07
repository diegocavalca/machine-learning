add(X, [], [X]).
add(X, [Y|Z], [Y|W]) :- add(X, Z, W).