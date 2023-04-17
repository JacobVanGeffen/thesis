(put 0 (2 2))   // Data store:  2 2                Index:  0 0 2
(flush)         // Data store: *2 2*               Index: *0 0 2*
(put 1 (3 3 3)) // Data store: *2 2* 3 3 3         Index: *0 0 2* 1 2 3
(put 0 (4 4 4)) // Data store: *2 2* 3 3 3 4 4 4   Index: *0 0 2* 1 2 3 0 5 3
(clean)         // Data store: *2 2* 3 3 3 4 4 4   Index:  1 2 3  0 5 3
