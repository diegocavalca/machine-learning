conta([],0).

conta([X|Cauda],Total) :- \+is_list(X), 
						  conta(Cauda, TotalCauda),
						  Total is TotalCauda + 1.

conta([X|Cauda],Total) :- is_list(X), 
						  conta(X, TotalX),
						  conta(Cauda, TotalCauda),
						  Total is TotalCauda + TotalX.