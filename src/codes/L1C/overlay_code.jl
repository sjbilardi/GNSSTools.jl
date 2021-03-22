"""
generate_overlay_code(prn::Int64)

Generate the overlay code for PRNs 1-63 using the S1 register only.
"""
function generate_overlay_code(prn::Int64)
    S1 = overlay_parms[prn]["init"]
    
end


"""
overlay_parms

Contains the 11-bit shift register taps and initial conditions
for each PRN.
"""
const overlay_parms = Dict( 1 => Dict("taps" => (3, 6, 9, 11),
                                      "init" => (1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0)),
                            2 => Dict("taps" => (4, 8, 9, 11),
                                      "init" => (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0)),
                            3 => Dict("taps" => (6, 8, 9, 11),
                                      "init" => (0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1)),
                            4 => Dict("taps" => (1, 8, 9, 11),
                                      "init" => (1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1)),
                            5 => Dict("taps" => (1, 2, 3, 8, 10, 11),
                                      "init" => (1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0)),
                            6 => Dict("taps" => (5, 6, 10, 11),
                                      "init" => (1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0)),
                            7 => Dict("taps" => (3, 5, 6, 7, 10, 11),
                                      "init" => (0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0)),
                            8 => Dict("taps" => (6, 8, 10, 11),
                                      "init" => (0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0)),
                            9 => Dict("taps" => (2, 7, 10, 11),
                                      "init" => (1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1)),
                           10 => Dict("taps" => (2, 3, 4, 7, 10, 11),
                                      "init" => (0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1)),
                           11 => Dict("taps" => (3, 5, 6, 7, 8, 9, 10, 11),
                                      "init" => (0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1)),
                           12 => Dict("taps" => (1, 4, 7, 8, 10, 11),
                                      "init" => (0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0)),
                           13 => Dict("taps" => (1, 3, 4, 6, 7, 8, 10, 11),
                                      "init" => (1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0)),
                           14 => Dict("taps" => (1, 2, 4, 7, 8, 9, 10, 11),
                                      "init" => (0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0)),
                           15 => Dict("taps" => (1, 2, 4, 5, 7, 8, 9, 11),
                                      "init" => (1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0)),
                           16 => Dict("taps" => (3, 5, 9, 11),
                                      "init" => (1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0)),
                           17 => Dict("taps" => (2, 4, 5, 7, 8, 9, 10, 11),
                                      "init" => (1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1)),
                           18 => Dict("taps" => (2, 4, 6, 7, 10, 11),
                                      "init" => (1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 0)),
                           19 => Dict("taps" => (2, 4, 5, 6, 7, 11),
                                      "init" => (1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1)),
                           20 => Dict("taps" => (2, 5, 6, 7, 8, 11),
                                      "init" => (0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0)),
                           21 => Dict("taps" => (1, 3, 4, 7, 8, 9, 10, 11),
                                      "init" => (0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0)),
                           22 => Dict("taps" => (1, 2, 5, 6, 7, 8, 10, 11),
                                      "init" => (0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0)),
                           23 => Dict("taps" => (2, 3, 4, 5, 8, 11),
                                      "init" => (0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0)),
                           24 => Dict("taps" => (2, 4, 7, 11),
                                      "init" => (1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1)),
                           25 => Dict("taps" => (1, 4, 5, 9, 10, 11),
                                      "init" => (1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1)),
                           26 => Dict("taps" => (1, 4, 8, 11),
                                      "init" => (1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1)),
                           27 => Dict("taps" => (3, 5, 7, 8, 10, 11),
                                      "init" => (1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0)),
                           28 => Dict("taps" => (4, 5, 6, 11),
                                      "init" => (0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)),
                           29 => Dict("taps" => (1, 2, 3, 4, 7, 9, 10, 11),
                                      "init" => (1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1)),
                           30 => Dict("taps" => (1, 3, 4, 5, 8, 11),
                                      "init" => (0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0)),
                           31 => Dict("taps" => (1, 2, 3, 4, 5, 8, 9, 11),
                                      "init" => (1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0)),
                           32 => Dict("taps" => (1, 4, 5, 6, 10, 11),
                                      "init" => (0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1)),
                           33 => Dict("taps" => (1, 4, 7, 9, 10, 11),
                                      "init" => (1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0)),
                           34 => Dict("taps" => (1, 4, 6, 7, 10, 11),
                                      "init" => (1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1)),
                           35 => Dict("taps" => (2, 4, 6, 9, 10, 11),
                                      "init" => (1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0)),
                           36 => Dict("taps" => (2, 3, 4, 9, 10, 11),
                                      "init" => (0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0)),
                           37 => Dict("taps" => (5, 6, 7, 11),
                                      "init" => (0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1)),
                           38 => Dict("taps" => (1, 3, 5, 6, 7, 11),
                                      "init" => (0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1)),
                           39 => Dict("taps" => (1, 2, 6, 11),
                                      "init" => (1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0)),
                           40 => Dict("taps" => (2, 3, 4, 6, 7, 8, 9, 11),
                                      "init" => (0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0)),
                           41 => Dict("taps" => (5, 6, 7, 8, 10, 11),
                                      "init" => (0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1)),
                           42 => Dict("taps" => (3, 4, 5, 9, 10, 11),
                                      "init" => (1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0)),
                           43 => Dict("taps" => (1, 4, 5, 6, 8, 11),
                                      "init" => (0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1)),
                           44 => Dict("taps" => (2, 3, 5, 6, 7, 8, 9, 11),
                                      "init" => (1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1)),
                           45 => Dict("taps" => (1, 2, 4, 6, 10, 11),
                                      "init" => (0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0)),
                           46 => Dict("taps" => (3, 4, 5, 7, 8, 11),
                                      "init" => (0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1)),
                           47 => Dict("taps" => (3, 6, 8, 11),
                                      "init" => (1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0)),
                           48 => Dict("taps" => (1, 3, 4, 6, 8, 11),
                                      "init" => (0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0)),
                           49 => Dict("taps" => (1, 2, 3, 5, 6, 7, 9, 11),
                                      "init" => (0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0)),
                           50 => Dict("taps" => (1, 2, 7, 8, 9, 11),
                                      "init" => (0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1)),
                           51 => Dict("taps" => (1, 3, 4, 5, 7, 8, 10, 11),
                                      "init" => (1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1)),
                           52 => Dict("taps" => (1, 3, 5, 6, 10, 11),
                                      "init" => (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                           53 => Dict("taps" => (2, 4, 5, 6, 8, 9, 10, 11),
                                      "init" => (1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0)),
                           54 => Dict("taps" => (1, 2, 6, 9, 10, 11),
                                      "init" => (1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 1)),
                           55 => Dict("taps" => (3, 7, 10, 11),
                                      "init" => (1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1)),
                           56 => Dict("taps" => (4, 6, 7, 11),
                                      "init" => (1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1)),
                           57 => Dict("taps" => (7, 9, 10, 11),
                                      "init" => (0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0)),
                           58 => Dict("taps" => (3, 5, 8, 11),
                                      "init" => (1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0)),
                           59 => Dict("taps" => (3, 8, 9, 11),
                                      "init" => (0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0)),
                           60 => Dict("taps" => (5, 6, 9, 11),
                                      "init" => (0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0)),
                           61 => Dict("taps" => (5, 9, 10, 11),
                                      "init" => (0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0)),
                           62 => Dict("taps" => (1, 2, 3, 4, 7, 8, 10, 11),
                                      "init" => (1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0)),
                           63 => Dict("taps" => (1, 2, 3, 4, 5, 6, 8, 11),
                                      "init" => (0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1)))