conta([],0).
conta([_|Y],Total) :- conta(Y, Subtotal), Total is Subtotal + 1.