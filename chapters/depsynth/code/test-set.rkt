// Test 1               // Test 2                // Test 3
(put 0 (1 2 3))         (put 0 (1 2 3 4))        (put 0 (1 2))
                        (put 5 (6 7 8 9))        (flush)
                                                 (put 3 (4 5 6))
                                                 (put 0 (7 8 9))
