# cagematch.tcl --
# Developed by Santiago Antolinez
# Lab of Dr. Jodi A. Hadden-Perilla (jhadden@udel.edu)
# Draw Polyhedron code + some functionality (Capsid Volume/ Sphericity)
# Code is able to draw 6 disctinct polyhedrons based on the following keywords:
#       -icosahedron      -- Icosahedron, vertices correspond to pentavalent capsomers          
#       -capsomers        -- Triangular-faced polyhedra, vertices correspond to capsomer centers
#       -geodesic         -- Geodesic icosahedron, vertices correspond to symmetry axes   
#       -kites            -- Disdyakis triacontahedron, (kite-faced polyhedra)                  
#       -goldberg         -- Goldberg polyhedra (polyhedra with pentagonal and hexagonal faces) 
#       -kis              -- Hexapentakis goldberg polyhedra (apply kis operator to goldberg)

package require struct::list
package require struct::set

package provide cagematch 1.0

set clusdir [file dirname [file normalize [info script]]]

proc InfoCageMatch {} {
    vmdcon -info "CageMatch is a VMD plugin for analyzing protein cages through"
    vmdcon -info "polyhedral representations + some functionality."
    vmdcon -info ""
    vmdcon -info "Available functions include:"
    vmdcon -info "  - DrawPolyhedron: Draw polyhedral representation of given container"
    vmdcon -info "  - ViewClusterPoints: Vizualize the initial clustering points as"
    vmdcon -info "                       determined by given atomselection"
    vmdcon -info "  - ViewClusterMembers: Make representation of showing the cluster"
    vmdcon -info "                        constituents for a given vertex ID"
    vmdcon -info "  - Member2Vertex: Return list of vertex IDs to which given"
    vmdcon -info "                   segnames/fragments belong to for the current polyhedron"
    vmdcon -info "  - Vertex2Member: Return list of cluster members for given vertices"
    vmdcon -info "  - SavePoly: Save polyhedral representation to tcl file"
    vmdcon -info "  - LoadPoly: Load polyhdral representation from file"
    vmdcon -info "  - SurfaceArea: Calculate surface area of current representation"
    vmdcon -info "  - RepVolume: Calculate volume of current representation"
    vmdcon -info "  - Sphericity: Calculate sphericity of current representation"
    vmdcon -info "  - VertexDistance: Return distance between two vertices"
    vmdcon -info "  - VertexAngle: Return angle formed between three vertices"
    vmdcon -info "  - SetVertexColors: Change vertex colors"
    vmdcon -info "  - StopPoly: Disable the trace on the polyhedral representation"
    vmdcon -info "  - InfoCageMatch: Print this help text"
    error ""
}

proc __VCMUsage__ {} {
    vmdcon -info " Make representation selecting the constituents of a given vertices"
    vmdcon -info " Usage: ViewClusterMembers <VertexID list> \[options\]"
    vmdcon -info ""
    vmdcon -info " Options are:"
    vmdcon -info "   -mol <molid>     -- Molid. Default: top"
    vmdcon -info "   -rep <rep_style> -- Rendering method. Defaults to current default method"
    vmdcon -info "   -sel <selection> -- Additional atomselection. Default: all"
    vmdcon -info "   -color <coloring_method> -- Coloring method. Defaults to current default color"
    vmdcon -info "   -material <material_name> -- Material setting. Defaults to current default material"
    vmdcon -info ""
    error ""

}

proc ViewClusterMembers {args} {
    if {[llength $args]==0} {
	__VCMUsage__
    }

    set clusterIDs [lindex $args 0]
    set args [lreplace $args 0 0]

    
    set flag [lsearch $args "-mol"]
    if {$flag != -1} {
	set molid [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set molid top
    }

    set flag [lsearch $args "-rep"]
    if {$flag != -1} {
	set rep [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set rep ""; #Lines
    }

    set flag [lsearch $args "-sel"]
    if {$flag != -1} {
	set sel [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set sel all
    }

    set flag [lsearch $args "-color"]
    if {$flag != -1} {
	set color [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set color ""; #Name
    }

    set flag [lsearch $args "-material"]
    if {$flag != -1} {
	set material [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set material ""; #Opaque
    }

    if {[llength $args]>0} {
	__VCMUsage__
    }
    
    set seltext "($sel) and $::CageMatch::CLUSTERBY"
    foreach i $clusterIDs {set seltext "$seltext $::CageMatch::ClusterMembers($i)"}

    mol material $material
    mol color $color
    mol representation $rep
    mol selection $seltext
    mol addrep $molid 
}

proc ViewClusterPoints {args} {
    if {[llength $args]==0} {
	vmdcon -info " Draw spheres representing the location of points used in inital clustering for a given selection"
	vmdcon -info " Usage: ViewClusterPoints <selection> \[options\]"
	vmdcon -info ""
	vmdcon -info " Options are:"
	vmdcon -info "   -mol <molid>         -- Molid on which to draw. Default: top"
	vmdcon -info "   -cagesel <selection> -- Atomselection defining container. Default: protein"
	vmdcon -info "   -clusterby <segname/fragment> -- Variable to use for unique identification of chains when clustering"
	vmdcon -info "   -color <color>       -- Color of spheres. Default: black"
	vmdcon -info "   -rad <radius>        -- Radius of spheres. Default: 4"
	vmdcon -info "   -res <resolution>    -- Resolution used when drawing spheres. Default: 20"
	vmdcon -info ""
	error ""
    }

    set selection [lindex $args 0]
    set args [lreplace $args 0 0]

    
    set flag [lsearch $args "-mol"]
    if {$flag != -1} {
	set molid [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set molid top
    }

    set flag [lsearch $args "-clusterby"]
    if {$flag != -1} {
	set clusterby [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set clusterby fragment
    }

    set flag [lsearch $args "-color"]
    if {$flag != -1} {
	set color [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set color black
    }

    set flag [lsearch $args "-rad"]
    if {$flag != -1} {
	set rad [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set rad 4
    }

    set flag [lsearch $args "-res"]
    if {$flag != -1} {
	set res [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set res 20
    }
    
    
    set flag [lsearch $args "-cagesel"]
    if {$flag != -1} {
	set cagesel [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set cagesel protein	
    }

    set all [atomselect $molid "$cagesel"]
    set segNames [lsort -unique [$all get $clusterby]]
    $all delete
    if {[llength $args]>0 || ($clusterby!="segname" && $clusterby!="fragment")} {
	if {[llength $args]>0} {vmdcon -err  "Unrecognized option: $args"}
	vmdcon -info " Usage: ViewClusterPoints <selection> \[options\]"
	vmdcon -info ""
	vmdcon -info " Options are:"
	vmdcon -info "   -mol <molid>     -- Molid on which to draw polyhedra representation. Default: top"
	vmdcon -info "   -cagesel <selection> -- Atomselection defining container. Default: protein"
	vmdcon -info "   -clusterby <segname/fragment> -- Variable to use for unique identification of chains when clustering"
	vmdcon -info "   -color <color>       -- Color of spheres. Default: black"
	vmdcon -info "   -rad <radius>        -- Radius of spheres. Default: 4"
	vmdcon -info "   -res <resolution>    -- Resolution used when drawing spheres. Default: 20"
	vmdcon -info ""
	error ""
    }

    graphics $molid delete all
    graphics $molid color $color
    foreach seg $segNames {
    	set sel [atomselect $molid "$clusterby $seg and ($selection)" ]
        graphics $molid sphere   [measure center $sel] radius $rad resolution $res
    	$sel delete
    }

    
}

proc StopPoly {args} {
    if {[llength $args] != 1 || ( $args != 1 && $args !=0)} {
	vmdcon -info " Disable polyhedra trace"
	vmdcon -info " Usage: StopPoly <delpoly>"
	vmdcon -info ""
	vmdcon -info " <delpoly> options are:"
	vmdcon -info "   1 -- Delete last drawn polyhedron"
	vmdcon -info "   0 -- Do not delete last drawn polyhedron"
	vmdcon -info ""
	error ""
    }

    if {![info exists ::CageMatch::TRACEENABLED]} {
	vmdcon -error " No trace enabled"
	error ""
    }
    
    set TRACEMOLID $::CageMatch::TRACEMOLID
    if {$TRACEMOLID=="top"} {set TRACEMOLID [molinfo top]}
    set TRACEENABLED $::CageMatch::TRACEENABLED

    if {$args} {
	::CageMatch::CleanLast $TRACEMOLID
    }
    
    if {$TRACEENABLED} {
	uplevel trace remove variable vmd_frame($TRACEMOLID) write ::CageMatch::TracerFunc
	set ::CageMatch::TRACEENABLED 0
    }
    if {$::CageMatch::TRACECOLOR} {set ::CageMatch::TRACECOLOR 0}
    return
}

proc __DrawPolyhedron_usage__ {} {
    vmdcon -info "Usage: DrawPolyhedron <polyhedron> \[options\]"
    vmdcon -info "Available polyhedra representations (choose one):"
    vmdcon -info "   icosahedron      -- Icosahedron, vertices correspond to pentavalent capsomers          "
    vmdcon -info "   capsomers        -- Triangular-faced polyhedra, vertices correspond to capsomer centers"
    vmdcon -info "   geodesic         -- Geodesic icosahedron, vertices correspond to symmetry axes   "
    vmdcon -info "   kites            -- Disdyakis triacontahedron, (kite-faced polyhedra)                  "
    vmdcon -info "   goldberg         -- Goldberg polyhedra (polyhedra with pentagonal and hexagonal faces) "
    vmdcon -info "   kis              -- Hexapentakis goldberg polyhedra (apply kis operator to goldberg)   "
    vmdcon -info ""
    vmdcon -info "Other Options (default values mentioned are for the first invocation, consecutive invocations default to previously set values):"
    vmdcon -info "   -mol <molid>     -- Molid on which to draw polyhedra representation. Default: top"
    vmdcon -info "   -draw <VEF>      -- Combination of strings V E F determines whether to draw (V)ertices,(E)dges, and/or (F)aces. Default: VE"
    vmdcon -info "   -sel <selection> -- Atomselection to use when updating representation. Default: name CA"
    vmdcon -info "   -recalc          -- Force calculation of clusters"    
    vmdcon -info "   -noicosa         -- No icosahedral symmetry present, disables representations related to icosahedral symmetry"
    vmdcon -info "   -icosa           -- Icosahedral symmetry present (default)"
    vmdcon -info "   -cagesel <selection> -- Atomselection defining container. Default: protein"
    vmdcon -info "   -clusterby <segname/fragment> -- Variable to use for unique identification of chains when clustering"
    vmdcon -info "   -clustersizes <list>   -- List of cluster sizes in which to group chains. Default: {5 6}"
    vmdcon -info "   -gcenters <on/off> -- Draw face centers for goldberg representation. Deafault: off"
    vmdcon -info ""
    error ""
}

proc DrawPolyhedron {args} {
    if {![llength $args]} {
	__DrawPolyhedron_usage__
    }

    set Ttype [lindex $args 0]
    set args [lreplace $args 0 0]
    set allowedTypes {capsomers pentamers geodesic triangles kites twofold hexamers icosahedron goldberg kis}
    if {[lsearch $allowedTypes $Ttype]==-1} {
	vmdcon -err "Unrecognized option: $Ttype"
	__DrawPolyhedron_usage__	
    }
    set flag [lsearch $args "-draw"]
    if { $flag != -1} {
	set drawType [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set drawType $::CageMatch::TRACEDRAW
    }

    set flag [lsearch $args "-gcenters"]
    if {$flag != -1} {
	set gcenters [lindex $args [expr $flag +1]]
	set args [lreplace $args $flag [expr $flag +1]]
	if {$gcenters!= "on" && $gcenters !="off"} {
	    __DrawPolyhedron_usage__	
	} elseif {$gcenters == "on"} {
	    set ::CageMatch::GOLDBERGCENTER 1
	} else {
	    set ::CageMatch::GOLDBERGCENTER 0
	}	
    }

   
    set flag [lsearch $args "-mol"]
    if {$flag != -1} {
	set molid [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set molid $::CageMatch::TRACEMOLID
    }

    set flag [lsearch $args "-sel"]
    if {$flag != -1} {
	set selection [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set selection $::CageMatch::TRACESELECTION
    }

    set flag [lsearch $args "-clusterby"]
    if {$flag != -1} {
	set clusterby [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set clusterby $::CageMatch::CLUSTERBY
    }

    if { $clusterby!="segname" && $clusterby!="fragment"} {
	__DrawPolyhedron_usage__
    }

    if {$clusterby != $::CageMatch::CLUSTERBY} {
	set ::CageMatch::INITCLUSTER 0
    }
    
    set ::CageMatch::CLUSTERBY $clusterby

    set flag [lsearch $args "-clustersizes"]
    if {$flag != -1} {
	set clustersizes [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set clustersizes $::CageMatch::NUMBERMEMBERS
    }

    if {$clustersizes != $::CageMatch::NUMBERMEMBERS} {
	set ::CageMatch::INITCLUSTER 0
    }
    set ::CageMatch::NUMBERMEMBERS $clustersizes

    
    set flag [lsearch $args "-cagesel"]
    if {$flag != -1} {
	set cagesel [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set cagesel $::CageMatch::CAGESEL
    }

    if {$cagesel != $::CageMatch::CAGESEL} {
	set ::CageMatch::INITCLUSTER 0	
    }
    set ::CageMatch::CAGESEL $cagesel
    
    set flag [lsearch $args "-recalc"]
    if {$flag != -1} {
	set args [lreplace $args $flag $flag]
	set  ::CageMatch::INITCLUSTER 0
    }
    
    set flag1 [lsearch $args "-icosa"]
    set flag2 [lsearch $args "-noicosa"]

    if { $flag1 != -1 && $flag2 != -1} {
	__DrawPolyhedron_usage__
    } elseif {$flag2 != -1} {
	set args [lreplace $args $flag2 $flag2]
	set icosa 0
    } elseif {$flag1 != -1} {
	set args [lreplace $args $flag1 $flag1]
	set icosa 1
    } else {
	set icosa $::CageMatch::TRACEICOSA
    }

    if {!$icosa && ( $Ttype =="geodesic" || $Ttype == "kites" || $Ttype =="pentamers" ||$Ttype =="icosahedron") } {
	__DrawPolyhedron_usage__
    }
    if {$icosa != $::CageMatch::TRACEICOSA} {
	set  ::CageMatch::INITCLUSTER 0
    }

    if {!$::CageMatch::TRACECOLOR} {set ::CageMatch::TRACECOLOR 1}
    if {[llength $args] >0} {
	vmdcon -err "Unrecognized option: $args"
	__DrawPolyhedron_usage__
    }
    
    vmdcon -info "Drawing polyhedron $Ttype with options:"
    vmdcon -info "     Draw: $drawType"
    vmdcon -info "     molid: $molid"
    vmdcon -info "     selection: $selection"
    vmdcon -info "     cagesel:  $cagesel"
    vmdcon -info "     clusterby: $clusterby"
    vmdcon -info ""
    set args [list $Ttype $drawType $molid $selection $icosa]
    return [eval ::CageMatch::EnableTrace $args]
}

namespace eval ::CageMatch {
    # Vertex ID variables:
    variable PentamerIDs
    variable HexamerIDs
    variable TrifoldIDs
    variable TwofoldIDs
    variable GoldbergIDs
    variable GoldbergPentIDs
    variable GoldbergHexIDs
    
    # Arrays with vertex info:
    variable ClusterMembers
    variable ClusterCenters
    variable ClusterSelections

    # Arrays with Neighbour info:
    variable ClusterNeighbours  
    variable PentNeighbours  
    variable HexNeighbours
    variable SymmetryNeighbours
    variable KiteNeighbours
    variable TwofoldNeighbours
    variable HybridNeighbours
    variable GoldbergNeighbours
    variable GoldbergTriNeighbours
    
    # Capsid info:
    variable CageCenterSelection
    variable CapsidCenter
    variable CAPSOMERNUM
    variable Tnumber

    # Graphical Representation variables:
    variable FACECOLOR white
    variable EDGECOLOR gray
    variable FACEMATERIAL Transparent
    variable EDGEMATERIAL AOChalky
    variable VERTEXMATERIAL AOChalky
    variable KITEAXISTWOFOLD 1
    variable PENTAMERCOLOR red
    variable HEXAMERCOLOR white
    variable TRIFOLDCOLOR blue
    variable TWOFOLDCOLOR green
    variable GOLDBERGCOLOR black
    variable GOLDBERGCENTER 0
    variable VERTEXRAD 5
    variable VERTEXRES 25
    variable EDGERAD 2
    variable EDGERES 25

    # Variables for various settings:
    if {![info exists INITCLUSTER]} {
	variable INITCLUSTER 0
    }
    variable CLUSTERBY fragment
    variable NUMBERMEMBERS {5 6}
    variable KEEPSELECTIONS 1
    variable CLEANPREVIOUS 1
    variable CURRENTSELECTION ""
    variable LastDrawnPolygon {}

    # Variables for trace:
    variable TRACETYPE
    variable TRACEDRAW VE
    variable TRACESELECTION "name CA"
    variable TRACEMOLID top
    variable TRACEENABLED 0
    variable TRACEICOSA 1
    variable TRACECOLOR 0
    variable CAGESEL "protein"

    # add trace to vertex colors

    foreach ctrace [trace info variable TRACECOLOR] {
	trace remove variable TRACECOLOR {*}$ctrace
    }
    trace add variable TRACECOLOR write ::CageMatch::ToggleColorTrace
    
}

proc ::CageMatch::ToggleColorTrace {op name command} {
    variable TRACECOLOR
    if {$TRACECOLOR} {
	SetColorTrace
    } else {
	DisableColorTrace
    }
}

proc ::CageMatch::DisableColorTrace {} {
    variable PENTAMERCOLOR 
    variable HEXAMERCOLOR 
    variable TRIFOLDCOLOR
    variable TWOFOLDCOLOR
    variable GOLDBERGCOLOR

    set colorList {PENTAMERCOLOR HEXAMERCOLOR TRIFOLDCOLOR TWOFOLDCOLOR GOLDBERGCOLOR}

    foreach  col $colorList {
	foreach ctrace [trace info variable $col] {
	    trace remove variable $col {*}$ctrace
	}
    }
    

}

proc ::CageMatch::SetColorTrace {} {
    variable PENTAMERCOLOR 
    variable HEXAMERCOLOR 
    variable TRIFOLDCOLOR
    variable TWOFOLDCOLOR
    variable GOLDBERGCOLOR

    set colorList {PENTAMERCOLOR HEXAMERCOLOR TRIFOLDCOLOR TWOFOLDCOLOR GOLDBERGCOLOR}

    foreach  col $colorList {
	foreach ctrace [trace info variable $col] {
	    trace remove variable $col {*}$ctrace
	}
	trace add variable $col write ::CageMatch::ColorChangeTrace
    }
    

}

proc SetVertexColors {args} {
    eval ::CageMatch::SetVertexColors $args
}

proc ::CageMatch::SetVertexColors {args} {
    variable PENTAMERCOLOR 
    variable HEXAMERCOLOR 
    variable TRIFOLDCOLOR
    variable TWOFOLDCOLOR
    variable GOLDBERGCOLOR

    set colorList(pentamers) PENTAMERCOLOR
    set colorList(hexamers)  HEXAMERCOLOR
    set colorList(trifolds)  TRIFOLDCOLOR
    set colorList(twofolds)  TWOFOLDCOLOR
    set colorList(goldberg)    GOLDBERGCOLOR

    
    set largs [llength $args]
    if {$largs==0 || [expr $largs%2]!=0} {
	vmdcon -info "Usage: SetVertexColors <vertexType1> <color1> <vertexType2> <color2> ..."
	vmdcon -info ""
	vmdcon -info "Possible <vertexType> values are:"
	vmdcon -info "   - pentamers"
	vmdcon -info "   - hexamers"
	vmdcon -info "   - trifolds"
	vmdcon -info "   - twofolds"
	vmdcon -info "   - goldberg (all other vertices)"
	vmdcon -info "Colors can be any of the available ColorIDs"
	vmdcon -info ""
	PrintVcolorLegend
	error ""
    }

    foreach {vertexType color} $args {
	set $colorList($vertexType) $color
	
    }
    PrintVcolorLegend

}

proc ::CageMatch::DetClosestClusters {clusters} {

    set noclusters [llength $clusters]
    set last [expr $noclusters -1]
    set idx 0
    set closest_clusters {}
    foreach cluster $clusters {
	set mindist {}
	set CompareDist {}
	if {$idx == $last} break
	for { set i [expr $idx + 1] } { $i < $noclusters } { incr i } {
	    set other [lindex $clusters $i]
	    set dist [distanceClusters $cluster $other]
	    lappend CompareDist [list $idx $dist]
	    if { $mindist == {} || $mindist > $dist } {
		set mindist $dist
		set closest $i
	    }
	    
	}
	if {$idx ==0 } {
	    set minCompareDist $CompareDist
	} else {
	    set min1 [lindex $minCompareDist 0]
	    lassign $min1 i dist
	    if { $dist < $mindist} {
		set mindist $dist
		set closest $i
	    }
	    set tempDist [lrange $minCompareDist 1 end]
	    set minCompareDist {}
	    foreach group1 $tempDist group2 $CompareDist {
		if {[lindex $group1 1] <= [lindex $group2 1]} {
		    set val $group1
		} else {
		    set val $group2
		}
		lappend minCompareDist $val
	    }
	}
	
	lappend closest_clusters [list $idx $closest $mindist]
	incr idx
    }
    lappend closest_clusters [concat $idx {*}$minCompareDist]
    return $closest_clusters
}

proc ::CageMatch::UpdateClosestClusters {clusters new_cluster closest_clusters minidx minclosest minj} {
    
    if {$minidx > $minclosest} {incr minidx -1}
    
    set closest_clusters [lreplace $closest_clusters $minj $minj]

    # Update the indices
    set temp_closest  {}
    set double_check_dist {}
    set new_mindist {}
    set new_minclosest {}
    
    foreach group1 $closest_clusters {
	lassign $group1 idx closest dist
	if {$idx == $minclosest} continue
	if {$idx>$minclosest} {incr idx -1}
	if {$closest == $minclosest} {
	    lappend double_check_dist $idx
	    continue
	}
	
	if {$closest>$minclosest} {incr closest -1}
	set cluster [lindex $clusters $idx]
	set new_dist [distanceClusters $cluster $new_cluster]
	if {$dist > $new_dist} {
	    lappend temp_closest [list $idx $minidx $new_dist]
	} else {
	    lappend temp_closest [list $idx $closest $dist]
	}

	if {$new_dist < $new_mindist || $new_mindist== {} } {
	    set new_mindist $new_dist
	    set new_minclosest $idx
	}
    }
    set noclusters [llength $clusters]
    foreach idx $double_check_dist cluster [lmap x $double_check_dist {lindex $clusters $x}] {
	set mindist {}
	set minclosest {}
	for { set i 0 } { $i < $noclusters } { incr i } {
	    if { $i != $idx } {
		set other [lindex $clusters $i]
		set dist [distanceClusters $cluster $other]
		if { $i == $minidx && $new_mindist > $dist} {
		    set new_mindist $dist
		    set new_minclosest $idx
		}
		if { $mindist == {} || $mindist > $dist } {
		    set mindist $dist
		    set closest $i
		}
	    }
	}
	lappend temp_closest [list $idx $closest $mindist]
	
    }
    lappend temp_closest [list $minidx $new_minclosest $new_mindist]
    
    set closest_clusters $temp_closest
#    puts "length clusters: [llength $clusters], length closest [llength $closest_clusters]"
    return $closest_clusters
}

proc ::CageMatch::JoinNN {closest_clusters clusters datapoints} {
    set mindist {}
    set counter 0
    foreach  cl $closest_clusters {
	lassign $cl idx closest dist
	if { $mindist == {} || $mindist > $dist } {
	    set mindist    $dist
	    set minidx     $idx
	    set minclosest $closest
	    set minj $counter
	}
	incr counter
    }
    set new_cluster [determineNewCluster $clusters $minidx $minclosest $datapoints]
    set clusters    [lreplace $clusters $minidx $minidx $new_cluster]
    set clusters    [lreplace $clusters $minclosest $minclosest]
    return [list $clusters $new_cluster $minidx $minclosest $minj]
}

# Cluster Chains based on $CLUSTERBY (segnames or fragment) to get vertices for polihedra 

#    Basic cluster analysis:
#    - A dataset (a list of lists) consists of records describing the data
#    - Each record is a list of one or more values assumed to be the
#      coordinates in a vector space.
#    - The clustering algorithm will successively merge individual
#      data points into clusters, ending when all data points have been
#      merged into a single cluster.
#    - The output consists of a list of lists:
#      - each list contains a list of data points (indices into the original
#        list) forming the next cluster
#      - the second element is the center of that cluster
#      - the third element is the radius
#
#    Note:
#    There are many variations possible with respect to cluster
#    analysis. In this script each cluster is characterized by
#    the center of gravity of the points making up the cluster
#    and the maximum distance to that center is taken as the radius.
#    By redefining the procedure that determines the distance
#    between clusters and points and the procedure that determines
#    the characteristics of the clusters you can change the clustering
#    method.
#
# 
# Calculates the vertices for each of the capsomers, sets the center (according to
# the given selection) and sets makes a list of the segnames of every chain that
# make up a given vertex
proc ::CageMatch::ClusterBySegmentsOpt {{molid top} {frame now} {selection "name CA"}} {
    variable ClusterMembers
    variable ClusterCenters
    variable CAPSOMERNUM
    variable CLUSTERBY
    variable CAGESEL
    variable NUMBERMEMBERS
    variable ClusterMembers
    variable ClusterCenters
    array unset ClusterMembers *
    array unset ClusterCenters *
    set maxMembers [lindex [lsort -unique -integer $NUMBERMEMBERS] end]
    set all [atomselect $molid "$CAGESEL"]
    set segNames [lsort -unique [$all get $CLUSTERBY]]
    $all delete
    set datapoints {}
    set clusters {}
    set idx 0
    set indexList {}
    set resulting_clusters {}
    
    foreach seg $segNames {
    	set sel [atomselect $molid "$CLUSTERBY $seg and ($selection)" frame $frame]
	set point [measure center $sel]
	lappend datapoints $point
	set cluster_point [list  $idx $point  0.0]
	lappend clusters $cluster_point
	incr idx
    	$sel delete
    }

    set parsed_idx {}
    foreach cluster $clusters {
	lassign $cluster idx center rad
	if { [lsearch $parsed_idx $idx] != -1} {continue}
	
	
    }

    #
    # Second step: determine the minimum distances
    # Note:
    # The work could be halved, but the algorithm would
    # be a bit more complicated. Leave it for now
    #
    
    set closest_clusters [DetClosestClusters $clusters]
 
    #
    # Third step:
    # - Determine the minimum distance between two clusters
    # - Join them
    # - Determine the new minimum distances
    # - Continue until only one is left
    #

    while {[llength $clusters] > 1} {
	set mindist {}
	set counter 0
	foreach  cl $closest_clusters {
	    lassign $cl idx closest dist
	    if { $mindist == {} || $mindist > $dist } {
		set mindist    $dist
		set minidx     $idx
		set minclosest $closest
		set minj $counter
	    }
	    incr counter
	}
	set new_cluster [determineNewCluster $clusters $minidx $minclosest $datapoints]
	set clusters    [lreplace $clusters $minidx $minidx $new_cluster]
	set clusters    [lreplace $clusters $minclosest $minclosest]

	set len_new [llength [lindex $new_cluster 0]]
	
	if {$len_new > $maxMembers} break
	if {[lsearch $NUMBERMEMBERS $len_new] != -1} {
	    lappend resulting_clusters $new_cluster
	}
	
	set closest_clusters [UpdateClosestClusters $clusters $new_cluster $closest_clusters $minidx $minclosest $minj]
    }
    set final_list $resulting_clusters
    set final_list [RemoveExtraClusters $final_list]
    
    set clusterSegNames {}
    set i 1
    foreach cluster $final_list {
	foreach {indexes center} $cluster break
	set snames {}
	foreach idx $indexes {lappend snames [lindex $segNames $idx]}
	set ClusterMembers($i) $snames
	set ClusterCenters($i) $center
	incr i
    }
  
    set CAPSOMERNUM [array size ClusterMembers]
   
}

 # determineNewCluster --
 #    Compute the characteristics of the new cluster
 #
 # Arguments:
 #    clusters      All clusters
 #    idx1          Index of the first cluster
 #    idx2          Index of the second cluster
 #    datapoints    Original data points
 # Result:
 #    The new cluster
 #
proc ::CageMatch::determineNewCluster {clusters idx1 idx2 datapoints} {

    #
    # Determine new cluster indices
    #
    set indices1 [lindex $clusters $idx1 0]
    set indices2 [lindex $clusters $idx2 0]
    set new_indices [concat $indices1 $indices2]
    
    #
    # Determine the new centre (average of coordinates from all members)
    #    
    set coords [lmap x $new_indices {lindex $datapoints $x}]
    set sumcrd [vecadd {*}$coords]
    set new_centre [vecscale [expr 1.0/[llength $coords]] $sumcrd]

    #
    # Determine the new radius (max distance from center to points)
    #
    set distances [lmap x $coords {vecdist $x $new_centre}]
    set distances [lsort -real $distances]
    set new_rad [lindex $distances end]
    
    set new_cluster [list $new_indices $new_centre $new_rad]
    return $new_cluster   
}

# distanceCluster --
#    Compute the distance between two clusters
#
# Arguments:
#    cluster1      Data determining the first cluster
#    cluster2      Data determining the second cluster
# Result:
#    Distance between the clusters
# Note:
#    Just passing the centres and the radii will improve
#    the performance
#
proc ::CageMatch::distanceClusters {cluster1 cluster2} {
     foreach {indices1 centre1 radius1} $cluster1 {break}
     foreach {indices2 centre2 radius2} $cluster2 {break}
         # Use the Euclidean norm
     set dist [vecdist $centre1 $centre2]
     set dist [expr $dist - $radius1 - $radius2]
     return $dist
}



# Cleans initial cluster list, removing lower member-number clusters whose members are
# also present in any cluster with a higher number of members
proc ::CageMatch::RemoveExtraClusters {clusterList} {
    variable NUMBERMEMBERS

    set orderedMembers [lsort -unique -integer  $NUMBERMEMBERS]
    set maxMembers [lindex $orderedMembers end]
    
    foreach i $orderedMembers {set sortedList($i) {}}
    foreach cluster $clusterList {
	set x [llength [lindex $cluster 0]]
	lappend sortedList($x) $cluster
    }
    set new_clusters {}
    foreach current_i [lrange $orderedMembers 0 end-1] next_i [lrange $orderedMembers 1 end] {
	set next_indexes [lmap x $sortedList($next_i) {lindex $x 0}]
	set next_indexes [concat {*}$next_indexes]
	set curr_indexes [lmap x $sortedList($current_i) {llength [::struct::set intersect [lindex $x 0] $next_indexes]}]
	set new_clusters [concat $new_clusters [lmap x $sortedList($current_i) y $curr_indexes {if {$y==0} {list {*}$x} continue}]]
    }
    set new_clusters [concat $new_clusters $sortedList($maxMembers)]
    vmdcon -info "Total number of capsomers is [llength $new_clusters]"
    return $new_clusters
    
}

proc ::CageMatch::DistBasedNeighbours {} {
    variable ClusterMembers
    variable ClusterCenters
    variable PentamerIDs
    variable HexamerIDs
    
    variable ClusterNeighbours
    variable PentNeighbours
    variable HexNeighbours
    array unset ClusterNeighbours *
    array unset PentNeighbours *
    array unset HexNeighbours *
    
    set HexamerIDs {}
    set PentamerIDs {}
    set clusterIDs [array names ClusterMembers]
    
#    set clusterlengths [lmap x $clusterIDs {expr [llength $ClusterMembers($x)]}]
#    set PSEUDOHEX 0
#    if {[llength [lsort -unique $clusterlengths]] == 1} {set PSEUDOHEX 1}
    if {1} {
	foreach {i coord1} [array get ClusterCenters] {
	    # get the six closest neighbours
	    set dists [lmap x $clusterIDs {expr [vecdist $coord1 $ClusterCenters($x)]} ]
	    set neighbours [lrange [lsort -real $dists] 1 7] ;# get first 7 neighbours not including itself
	    set seventh [lindex $neighbours end]
	    set neighbours [lrange $neighbours 0 end-1] ;# only 6 neighbours

	    #if (7th- 6th)/7th > (6th -5th)/5th -> 5th and 6th are more similar -> hexavalent position
	    set sixth [lindex $neighbours end]
	    set fifth [lindex $neighbours end-1]
	    set diff1 [expr ($seventh - $sixth)/$seventh]
	    set diff2 [expr ($sixth - $fifth)/$fifth]
	    #	    if {[expr $seventh - $sixth] }
	    #check for outliers > 1.5*IQR+Q3 -> use 3*IQR for margin of error
#	    set Q3 [lindex $neighbours 4]
#	    set IQR [expr $Q3 - [lindex $neighbours 1]]
#	    set outliers [expr $Q3 + 3*$IQR]
	    # [lindex $neighbours end] > $outliers
	    if {$diff1 <$diff2} {
		set neighbours [lrange $neighbours 0 4]
	    }
	    set neighbourIDs {}
	    foreach item [lsort -unique $neighbours] {
		set matches [lsearch -all $dists $item]
		set neighbourIDs [concat $neighbourIDs [lmap x $matches {expr [lindex $clusterIDs $x]} ]]
	    }
	    
	    if {[llength $neighbourIDs] == 6} {
		lappend HexamerIDs $i		
	    } elseif {[llength $neighbourIDs] == 5} {
		lappend PentamerIDs $i
	    }
	    set ClusterNeighbours($i) $neighbourIDs
	}
	vmdcon -info "There are [llength $PentamerIDs] pentavalent capsomers"
	vmdcon -info "There are [llength $HexamerIDs] hexavalent capsomers"
	CalcPentHexNeighbours
    } else {
	foreach {i segnames} [array get ClusterMembers] {
	    if {[llength $segnames] == 5} {
		lappend PentamerIDs $i
	    } else {
		lappend HexamerIDs $i
	    }
	}
	vmdcon -info "There are [llength $PentamerIDs] pentamers"
	vmdcon -info "There are [llength $HexamerIDs] hexamers"
	CalcNeighbours
    }
}

# Calculates the neighbour list for each capsomer vertex
# neighbour lists here are used for pentamers,
# capsomers, and hexamers polyhedrons
proc ::CageMatch::CalcNeighbours {} {
    variable ClusterCenters
    variable ClusterNeighbours
    variable PentNeighbours
    variable HexNeighbours
    variable PentamerIDs
    variable HexamerIDs

    array unset ClusterNeighbours *
    array unset PentNeighbours *
    array unset HexNeighbours *
    
    foreach i $PentamerIDs {set ClusterNeighbours($i) {}}
    foreach i $HexamerIDs {set ClusterNeighbours($i) {}}
    foreach i $PentamerIDs {
	set coords1 $ClusterCenters($i)
	while {[llength $ClusterNeighbours($i)] < 5} {
	    set mindist {} 
	    foreach j $HexamerIDs {
		if {$i==$j} continue
		if {[lsearch $ClusterNeighbours($i) $j]!= -1} continue
		set dist [vecdist $coords1 $ClusterCenters($j)]
		if { $mindist > $dist || $mindist == {}} {
		    set mindist $dist
		    set minj $j	
		}
	    }
	    if {[lsearch $ClusterNeighbours($i) $minj]==-1} {lappend ClusterNeighbours($i) $minj}
	    if {[lsearch $ClusterNeighbours($minj) $i]==-1} {lappend ClusterNeighbours($minj) $i}
	}
    }
    
    foreach i $HexamerIDs {
	set coords1 $ClusterCenters($i)
	while {[llength $ClusterNeighbours($i)] < 6} {
	    set mindist {}
	    foreach j $HexamerIDs {
		if {$i==$j} continue
		if {[lsearch $ClusterNeighbours($i) $j]!= -1} continue
		set dist [vecdist $coords1 $ClusterCenters($j)]
		if { $mindist > $dist || $mindist == {}} {
		    set mindist $dist
		    set minj $j	
		}
	    }
	    if {[lsearch $ClusterNeighbours($i) $minj]==-1} {lappend ClusterNeighbours($i) $minj}
	    if {[lsearch $ClusterNeighbours($minj) $i]==-1} {lappend ClusterNeighbours($minj) $i}
	}
    }
    CalcPentHexNeighbours
}

proc ::CageMatch::CalcPentHexNeighbours {} {
    variable ClusterCenters
    variable ClusterNeighbours
    variable PentNeighbours
    variable HexNeighbours
    variable PentamerIDs
    variable HexamerIDs

    
    array unset PentNeighbours *
    array unset HexNeighbours *

    foreach i $PentamerIDs {set PentNeighbours($i) {}}
    foreach i $PentamerIDs {
	set coords1 $ClusterCenters($i)
	while {[llength $PentNeighbours($i)] < 5} {
	    set mindist {}
	    foreach j $PentamerIDs {
		if {$i==$j} continue
		if {[lsearch $PentNeighbours($i) $j]!= -1} continue
		set dist [vecdist $coords1 $ClusterCenters($j)]
		if { $mindist > $dist || $mindist == {}} {
		    set mindist $dist
		    set minj $j
		}
	    }
	    if {[lsearch $PentNeighbours($i) $minj]==-1} {lappend PentNeighbours($i) $minj}
	    if {[lsearch $PentNeighbours($minj) $i]==-1} {lappend PentNeighbours($minj) $i}	    
	}
    }

    foreach i $HexamerIDs {
	set neighbours $ClusterNeighbours($i)
	foreach j $PentamerIDs {
	    set key [lsearch $neighbours $j]
	    if {$key!=-1} {
		set neighbours [lreplace $neighbours $key $key]
	    }
	}
	set HexNeighbours($i) $neighbours
    }

}

# Calculate the symmetry axis vertices, the segmnames of the 6 chains that make
# up said vertices, and the neighbour lists for the different polyhedra
proc ::CageMatch::SymmetryAxis {{molid top} {frame now} {selection "name CA"}} {
    variable PentamerIDs
    variable HexamerIDs
    variable ClusterCenters
    variable ClusterSelections
    variable CAPSOMERNUM
    variable ClusterMembers
    variable ClusterNeighbours
    variable PentNeighbours
    variable HexNeighbours
    variable TrifoldIDs
    variable TwofoldIDs
    variable TRACEICOSA
    variable CLUSTERBY
    variable CAGESEL
    
    variable SymmetryNeighbours
    variable KiteNeighbours
    variable TwofoldNeighbours
    variable Tnumber

    array unset SymmetryNeighbours *
    array unset KiteNeighbours *
    array unset TwofoldNeighbours *

    
    
    if {!$TRACEICOSA} {
	set TrifoldIDs {}
	set TwofoldIDs {}
	vmdcon -info ""
	vmdcon -info "No icosahedral symmetry, skipping calculation of icosahedral symmetry vertices"
	array unset SymmetryNeighbours
	array unset KiteNeighbours
	array unset TwofoldNeighbours
	return
    }

    
    set Tnumber [expr [llength $HexamerIDs]/10 + 1]
    vmdcon -info "T number is: $Tnumber"
    vmdcon -info ""
    vmdcon -info "Calculating icosahedral symmetry vertices"
    
    set NewStart [expr $CAPSOMERNUM +1]
    set TriangleList [LocateTriangles pentamers]
    set PentSegNames {}
    foreach i $PentamerIDs {set PentSegNames [concat $PentSegNames $ClusterMembers($i)]}
    
    #set all [atomselect $molid "$CAGESEL and not $CLUSTERBY $PentSegNames"]
    set all [atomselect $molid "$CAGESEL"]
    set segNames [lsort -unique [$all get $CLUSTERBY]]
    $all delete
    
    set datapoints {}
    foreach seg $segNames {
    	set sel [atomselect $molid "$CLUSTERBY $seg and ($selection)" frame $frame]
    	lappend datapoints [measure center $sel]
    	$sel delete
    }

    set FaceCenters {}
    foreach trig $TriangleList {
	foreach {i j k} $trig break
	lappend FaceCenters [vecscale [expr 1./3.] [vecadd $ClusterCenters($i) $ClusterCenters($j) $ClusterCenters($k)]]
    }
    # draw color black
    # foreach F $FaceCenters {draw sphere $F radius 5 resolution 25}
    set count $NewStart
    set TrifoldIDs {}
    array unset Vertex2Cluster
    if {$Tnumber==3} {
	set TrifoldIDs $HexamerIDs
	foreach trig $TriangleList {
	    foreach {i j k} $trig break
	    set N1 [::struct::set intersect $ClusterNeighbours($i) $ClusterNeighbours($j)]
	    set N2 [::struct::set intersect $N1 $ClusterNeighbours($k)]
	    set Vertex2Cluster($i,$j,$k) $N2
	}
    } else {
	foreach center $FaceCenters trig $TriangleList {
	    foreach {i j k} $trig break
	    set Vertex2Cluster($i,$j,$k) $count
	    set clustersegids {}
	    set pointids {}
	    while {[llength $pointids]<6} {
		set mindist {}
		for {set i 0} {$i< [llength $datapoints]} {incr i} {
		    set coord [lindex $datapoints $i]
		    set dist [vecdist $center $coord]
		    if {[lsearch $pointids $i]!=-1} continue
		    if {$mindist>$dist || $mindist == {}} {
			set mindist $dist
			set minI $i
		    }
		}
		lappend pointids $minI
	    }
	    foreach j $pointids {lappend clustersegids [lindex $segNames $j]}
	    set sel [atomselect $molid "($selection) and $CLUSTERBY $clustersegids"]
	    set ClusterMembers($count) $clustersegids
	    set ClusterCenters($count) [measure center $sel]
	    lappend TrifoldIDs $count
	    $sel delete
	    incr count
	}
    }

    # Obtain Twofold symmetry points
    set TwofoldIDs {}
    foreach i $PentamerIDs {
	set coord1 $ClusterCenters($i)
	foreach j $PentNeighbours($i) {
	    if {$i==$j} continue
	    if {[lsearch [array names EdgeCenters] "$i,$j"]!=-1 || [lsearch [array names EdgeCenters] "$j,$i"]!=-1} continue
	    set coord2 $ClusterCenters($j)
	    set EdgeCenters($i,$j) [vecscale 0.5 [vecadd $coord1 $coord2]]
	}
    }
    # draw color purple
    # foreach name [array names EdgeCenters] {draw sphere $EdgeCenters($name) radius 5 resolution 25}
    array unset Edges2Cluster
    if {$Tnumber==4 } {
	set TwofoldIDs $HexamerIDs
	foreach name [array names EdgeCenters] {
	    foreach {i j} [split $name ","] break
	    set N1 [::struct::set intersect $ClusterNeighbours($i) $ClusterNeighbours($j)]
	    set Edges2Cluster($name) $N1	    
	}
    } else {
	foreach name [array names EdgeCenters] {
	    set center $EdgeCenters($name)
	    set Edges2Cluster($name) $count
	    set clustersegids {}
	    set pointids {}
	    while {[llength $pointids]<6} {
		set mindist {}
		for {set i 0} {$i< [llength $datapoints]} {incr i} {
		    set coord [lindex $datapoints $i]
		    set dist [vecdist $center $coord]
		    if {[lsearch $pointids $i]!=-1} continue
		    if {$mindist>$dist || $mindist == {}} {
			set mindist $dist
			set minI $i
		    }
		}
		lappend pointids $minI
	    }
	    foreach j $pointids {lappend clustersegids [lindex $segNames $j]}
	    set sel [atomselect $molid "($selection) and $CLUSTERBY $clustersegids"]
	    set ClusterMembers($count) $clustersegids
	    set ClusterCenters($count) [measure center $sel]
	    lappend TwofoldIDs $count
	    $sel delete
	    incr count
	}
    }

    # Find Neighbours based on the Icosahedral sides
    # Check each triangular face for the points that are in it
    # Add to neighbours
    foreach trig $TriangleList {
	foreach {i j k} $trig break
	set Edges {}
	set EdgeVertices [list [list $i $j] [list $j $k] [list $i $k]]
	if {[lsearch [array names Edges2Cluster] "$i,$j"]!=-1} {
	    lappend Edges $Edges2Cluster($i,$j)
	} else {
	    lappend Edges $Edges2Cluster($j,$i)
	}
	if {[lsearch [array names Edges2Cluster] "$j,$k"]!=-1} {
	    lappend Edges $Edges2Cluster($j,$k)
	} else {
	    lappend Edges $Edges2Cluster($k,$j)
	}
	if {[lsearch [array names Edges2Cluster] "$i,$k"]!=-1} {
	    lappend Edges $Edges2Cluster($i,$k)
	} else {
	    lappend Edges $Edges2Cluster($k,$i)
	}
	set vertex $Vertex2Cluster($i,$j,$k)
	foreach v $trig {
	    lappend KiteNeighbours($v) $vertex
	    lappend KiteNeighbours($vertex) $v
	}
	foreach edge $Edges Vertices $EdgeVertices {
	    lappend KiteNeighbours($edge) $vertex
	    lappend KiteNeighbours($vertex) $edge
	    foreach v $trig {
		if {[lsearch $KiteNeighbours($edge) $v]==-1 && [lsearch $Vertices $v]!= -1} {
		    lappend KiteNeighbours($edge) $v
		    lappend KiteNeighbours($v) $edge
		    lappend SymmetryNeighbours($edge) $v
		    lappend SymmetryNeighbours($v) $edge
		}
	    }
	    foreach edge2 $Edges {
		if {$edge==$edge2} continue
		if {[lsearch $KiteNeighbours($edge) $edge2]==-1} {
		    lappend KiteNeighbours($edge) $edge2
		    lappend KiteNeighbours($edge2) $edge
		    lappend SymmetryNeighbours($edge) $edge2
		    lappend SymmetryNeighbours($edge2) $edge
		    lappend TwofoldNeighbours($edge) $edge2
		    lappend TwofoldNeighbours($edge2) $edge
		}
	    }
	}
    }
}

# Determines the location of the vertices for the goldbergball/Hybrid representation
proc ::CageMatch::GoldbergVertex {{molid top} {frame now} {selection "name CA"}} {
    variable PentamerIDs
    variable HexamerIDs
    variable TrifoldIDs
    variable TwofoldIDs
    variable GoldbergIDs
    variable GoldbergPentIDs
    variable GoldbergHexIDs
    variable CLUSTERBY
    variable CAGESEL
    
    variable ClusterCenters
    variable ClusterSelections
    variable CAPSOMERNUM
    variable ClusterMembers
    variable ClusterNeighbours
    variable PentNeighbours
    variable HexNeighbours
    
    variable HybridNeighbours
    variable GoldbergNeighbours
    variable GoldbergTriNeighbours
    array unset HybridNeighbours *
    array unset GoldbergNeighbours *
    array unset GoldbergTriNeighbours *

    vmdcon -info "Calculating goldberg vertices"
    set NewStart [llength [lsort -unique [concat $PentamerIDs $HexamerIDs $TrifoldIDs $TwofoldIDs]]]
    incr NewStart
    set TriangleList [LocateTriangles capsomers]
    lassign  [SetupTypes capsomers 1] indexList neighbourList

    set all [atomselect $molid "$CAGESEL"]
    set segNames [lsort -unique [$all get $CLUSTERBY]]
    $all delete

    set datapoints {}
    foreach seg $segNames {
    	set sel [atomselect $molid "$CLUSTERBY $seg and ($selection)" frame $frame]
    	lappend datapoints [measure center $sel]
    	$sel delete
    }

    set FaceCenters {}
    foreach trig $TriangleList {
 	foreach {i j k} $trig break
	lappend FaceCenters [vecscale [expr 1./3.] [vecadd $ClusterCenters($i) $ClusterCenters($j) $ClusterCenters($k)]]
    }
#    draw color black
#    foreach F $FaceCenters {draw sphere $F radius 5 resolution 25}
    set count $NewStart
    set GoldbergIDs {}
    array unset Vertex2Cluster
    set isVertexTri 0
#    puts "got to this point"
    foreach center $FaceCenters trig $TriangleList {
	set clustersegids {}
	set pointids {}
	while {[llength $pointids]<6} {
	    set mindist {}
	    for {set i 0} {$i< [llength $datapoints]} {incr i} {
		set coord [lindex $datapoints $i]
		set dist [vecdist $center $coord]
		if {[lsearch $pointids $i]!=-1} continue
		if {$mindist>$dist || $mindist == {}} {
		    set mindist $dist
		    set minI $i
		}
	    }
	    lappend pointids $minI
	}
	foreach j $pointids {lappend clustersegids [lindex $segNames $j]}
	if { [llength [::struct::set intersect $trig $HexamerIDs]]==3} {
	    foreach k $TrifoldIDs {
		if {[llength [::struct::set intersect $clustersegids $ClusterMembers($k)]]==6} {
		    set isVertexTri $k
		    break
		}
	    }
	}
	lassign $trig i j k
	if {$isVertexTri} {
	    lappend GoldbergIDs $isVertexTri
	    set Vertex2Cluster($i,$j,$k) $isVertexTri
	    set isVertexTri 0
	} else {
	    set sel [atomselect $molid "($selection) and $CLUSTERBY $clustersegids"]
	    set ClusterMembers($count) $clustersegids
	    set ClusterCenters($count) [measure center $sel]
	    set Vertex2Cluster($i,$j,$k) $count
	    lappend GoldbergIDs $count
	    $sel delete
	    incr count
	}
	
    }

    # Criteria to find Hybrid Neighbours:
    # 1. All goldberg vertices with the capsomer vertices that make up the
    #    corresponding triangle
    # 2. Only 2 capsomer vertices are in the intersection of TempNeighbours
    #    (contains only capsomer vertices) for any 2 vertices in GoldbergIDs
    array unset TempNeighbours *
    array unset HybridNeighbours *
    array unset GoldbergNeighbours *
    array unset GoldbergTriNeighbours *

    foreach trig $TriangleList {
	lassign $trig i j k 

	set vertex $Vertex2Cluster($i,$j,$k)
	
	foreach v $trig {
	    lappend HybridNeighbours($v) $vertex
	    lappend HybridNeighbours($vertex) $v
	    lappend TempNeighbours($vertex) $v
	}
    }
    
    set CheckedNeighbours {}
    foreach i $GoldbergIDs {
	foreach j $GoldbergIDs {
	    if {$i==$j} continue
	    if {[lsearch $CheckedNeighbours "$i,$j"] != -1} continue
	    if {[llength [::struct::set intersect $TempNeighbours($i) $TempNeighbours($j)]]==2} {
		lappend HybridNeighbours($i) $j
		lappend HybridNeighbours($j) $i
		lappend GoldbergNeighbours($i) $j
		lappend GoldbergNeighbours($j) $i
	    }
	    lappend CheckedNeighbours $i,$j $j,$i
	}
    }
    array set GoldbergTriNeighbours [array get GoldbergNeighbours]
    set GoldbergPentIDs {}
    set GoldbergHexIDs {}
    # set the pentamers for Goldberg as the center of all hybrid neighbours,same for hexamers
    foreach i $PentamerIDs {
        # set members {}
	# foreach j $HybridNeighbours($i) {
	#     set members [concat $members $ClusterMembers($j)]
	#     lappend GoldbergTriNeighbours($j) $count
	# }
	set GoldbergTriNeighbours($count) $HybridNeighbours($i)
	set GoldbergNeighbours($count) {}
	# set members  [lsort -unique $members]
	# set sel [atomselect $molid "($selection) and $CLUSTERBY $members"]
	# set ClusterCenters($count) [measure center $sel]
	# $sel delete
	# set ClusterMembers($count) $members
	lappend GoldbergPentIDs $count
	incr count
    }

    foreach i $HexamerIDs {
        # set members {}
	# foreach j $HybridNeighbours($i) {
	#     set members [concat $members $ClusterMembers($j)]
	#     	    lappend GoldbergTriNeighbours($j) $count
	# }
	set GoldbergTriNeighbours($count) $HybridNeighbours($i)
	set GoldbergNeighbours($count) {}
	# set members  [lsort -unique $members]
	# set sel [atomselect $molid "($selection) and $CLUSTERBY $members"]
	# set ClusterCenters($count) [measure center $sel]
	# $sel delete
	# set ClusterMembers($count) $members
	lappend GoldbergHexIDs $count
	incr count
    }
    UpdateGoldbergCenters
}


# Initializes clusters or updates the centers of vertices involved in a given
# polyhedra representation, then draws said representation
proc ::CageMatch::RunPolygon { Ttype {drawtype "VE"} {molid top} {frame now} {selection "name CA" }} {
    variable INITCLUSTER
    set allowedTypes {capsomers pentamers geodesic triangles kites twofold hexamers icosahedron goldberg kis}
    if {[lsearch $allowedTypes $Ttype]==-1} {
	error "AllowedTypes are  $allowedTypes"	
    }
    if {!$INITCLUSTER} {
	vmdcon -info "Initializing Clusters"
	InitializeClusters $molid $frame $selection
    } else {
	UpdateVertices $Ttype $frame $molid $selection
    }
    eval DrawPolygon $Ttype $molid $drawtype
}

proc ::CageMatch::FindCapsidCenter {{molid top} {frame now} {selection "name CA"}} {
    variable CapsidCenter
    variable CAGESEL
    set sel [atomselect $molid "($CAGESEL) and ($selection)" frame $frame]
    set CapsidCenter [measure center $sel]
    $sel delete
}
 
# Initializes clusters, finds segnames and centers of all vertices, all neighbourlists
# sorts capsomers into hexamers/pentamers and sets the atomselections for all vertices
proc ::CageMatch::InitializeClusters {{molid top} {frame now} {selection "name CA"}} {
    variable INITCLUSTER
    variable KEEPSELECTIONS

    ClusterBySegmentsOpt $molid $frame $selection
    DistBasedNeighbours
    SymmetryAxis $molid $frame $selection
    GoldbergVertex $molid $frame $selection
    if {$KEEPSELECTIONS} {
	SelectCluster $molid $frame $selection
    } else {
	FindCapsidCenter $molid $frame $selection
    }
    
    set INITCLUSTER 1 
}

# Make the atomselections for each of the vertices
# Atomselections are moved to global namespace so they arent deleted when exiting the proc
proc ::CageMatch::SelectCluster {{molid top} {frame now} {selection "name CA"}} {
    variable ClusterMembers
    variable ClusterSelections
    variable CURRENTSELECTION
    variable CLUSTERBY
    variable CageCenterSelection
    variable CapsidCenter
    variable CAGESEL
    CleanSelections
    set CURRENTSELECTION $selection
    foreach i [array names ClusterMembers] {
	set ClusterSelections($i) [atomselect $molid "($selection) and $CLUSTERBY $ClusterMembers($i)" frame $frame]
	$ClusterSelections($i) global
    }
    set CageCenterSelection [atomselect $molid "($CAGESEL) and ($selection)" frame $frame]
    set CapsidCenter [measure center $CageCenterSelection]
    $CageCenterSelection global
    
}

# Update the centers for a given polyhedron reprensentation
proc ::CageMatch::UpdateVertices {{Ttype "capsomers"} {frame now} {molid top} {selection "name CA"}} {
    variable ClusterMembers
    variable ClusterCenters
    variable CageCenterSelection
    variable KEEPSELECTIONS
    variable CURRENTSELECTION
    variable CAGESEL
    variable CLUSTERBY
    set indexList [SetupTypes $Ttype 0]
    if {$KEEPSELECTIONS} {
	if {$CURRENTSELECTION!=$selection} {SelectCluster $molid $frame $selection}
	UpdateSelections $frame $indexList
    } else {
	foreach i $indexList {
	    set sel [atomselect $molid "$CLUSTERBY $ClusterMembers($i) and ($selection)" frame $frame]
	    set ClusterCenters($i) [measure center $sel]
	    $sel delete	
	}
	FindCapsidCenter $molid $frame $selection
    }
    if {$Ttype=="goldberg"} {UpdateGoldbergCenters}
}

proc ::CageMatch::UpdateGoldbergCenters {} {
    variable GoldbergIDs
    variable GoldbergPentIDs
    variable GoldbergHexIDs
    variable ClusterCenters
    variable GoldbergTriNeighbours

    foreach i [concat $GoldbergPentIDs $GoldbergHexIDs] {
	set neighbours $GoldbergTriNeighbours($i)
	set coords [lmap x $neighbours {list {*}$ClusterCenters($x)}]
	set sum [vecadd {*}$coords]
	set l [expr 1.0/[llength $coords]]
	set ave [vecscale $sum $l]
	set ClusterCenters($i) $ave
    }
}

# Updates centers if KEEPSELECTIONS is on (atomselections are kept)
proc ::CageMatch::UpdateSelections {{frame now} {indexList "allVertices"} } {
    variable ClusterCenters
    variable ClusterSelections
    variable CapsidCenter
    variable CageCenterSelection
    if {$indexList == "allVertices"} {set indexList [array names ClusterSelections]}
    foreach i  $indexList {
	$ClusterSelections($i) frame $frame
	set ClusterCenters($i) [measure center $ClusterSelections($i)]
    }
    $CageCenterSelection frame $frame
    set CapsidCenter [measure center $CageCenterSelection]
}

proc ::CageMatch::CleanSelections {} {
    variable ClusterSelections
    variable CageCenterSelection
    uplevel #0 {
	foreach TemporaryCounter [array names ::CageMatch::ClusterSelections] {
	    set TemporaryCheck [lsearch [atomselect list] $::CageMatch::ClusterSelections($TemporaryCounter)]
	    if { $TemporaryCheck!=-1} {
		$::CageMatch::ClusterSelections($TemporaryCounter) delete
	    }
	    if {[lsearch [atomselect list] $::CageMatch::CageCenterSelection]!=-1} {
		$::CageMatch::CageCenterSelection delete
	    }
	}
	if {[info exists TemporaryCounter]} {unset TemporaryCounter}
	if {[info exists TemporaryCheck]  } {unset TemporaryCheck}
    }
    array unset ClusterSelections *
}

# Switch between keeping the atomselections for each vertex or calculating them every frame
# (Faster to keep them, more memory intensive)
# Default is to keep them
proc ::CageMatch::ToggleKeepSelections {{molid top} {frame now} {selection "name CA"}} {
    variable KEEPSELECTIONS
    variable ClusterSelections
    
    if {$KEEPSELECTIONS} {
	set KEEPSELECTIONS 0
	CleanSelections
	vmdcon -info "KEEPSELECTIONS is now $KEEPSELECTIONS"
	vmdcon -info "Atomselections for vertices will now be calculated for every subsequent update"
    } else {
	set KEEPSELECTIONS 1
	vmdcon -info "KEEPSELECTIONS is now $KEEPSELECTIONS"
	vmdcon -info "Atomselections for vertices will be calculated now and used for subsequent updates"
	vmdcon -info "Parameters for atomselection calculation:"
	vmdcon -info "      molid: $molid"
	vmdcon -info "      frame: $frame"
	vmdcon -info "      selection: $selection"
	SelectCluster $molid $frame $selection
    }
    
}

proc Vertex2Member {args} {
    if {![info exists ::CageMatch::TRACETYPE]} {
	error "Running DrawPolyhedron before this is required"
    }
    if {[llength $args]!=1} {
	vmdcon -info "Return cluster members of given vertices"
	vmdcon -info "Usage: Vertex2Member <VertexID list>"
	error ""
    }
    return [eval ::CageMatch::Vertex2segname "$args" ]
}

proc ::CageMatch::Vertex2segname {vertexids} {
    variable ClusterMembers
    set results {}
    foreach id $vertexids {
	lappend results $ClusterMembers($id)
    }
    return $results
}


proc Member2Vertex {args} {
    if {![info exists ::CageMatch::TRACETYPE]} {
	error "Running DrawPolyhedron before this is required"
    }
    if {[llength $args]!=1} {
	vmdcon -info "Return  vertex IDs in  the current representation to which segnames/fragments belongs"
	vmdcon -info "Usage: Member2Vertex <fragment/segname list>"
	error ""
    }
    return [eval ::CageMatch::Segname2vertex "$args" $::CageMatch::TRACETYPE]
}

# Returns the vertex IDs of all the vertices to which the segname belongs
proc ::CageMatch::Segname2vertex {segname {Ttype "capsomers"}} {
    variable ClusterMembers
    set indexList [SetupTypes $Ttype 0]

    foreach seg $segname {
	set segList {}
	foreach i $indexList {
	    if { [lsearch $ClusterMembers($i) $seg] != -1} {
		lappend segList $i
	        continue
	    }
	}
	lappend vertexList $segList
    }
    return $vertexList    
}

# returns a list of all possible triangles in a given polyhedra
proc ::CageMatch::LocateTriangles {{Ttype "capsomers"}} {
    foreach {indexList neighbourList} [SetupTypes $Ttype 1] break
    array set neighbours $neighbourList
       
    set TriangleList {}
    foreach i $indexList {
	set Vertex1neighbours $neighbours($i)
	foreach j $Vertex1neighbours {
	    set Vertex2neighbours $neighbours($j)
	    set Vertex3 [::struct::set intersect $Vertex1neighbours $Vertex2neighbours]

	    foreach vex $Vertex3 {
		if {[lsearch $TriangleList [lsort -integer [list $i $j $vex]]]==-1} {
		    lappend TriangleList [lsort -integer [list $i $j $vex]]
		}
	    }
	}
    }
    return $TriangleList
}

proc ::CageMatch::CalcTrianglePlane {i j k} {
    variable ClusterCenters
    set p1 $ClusterCenters($i)
    set p2 $ClusterCenters($j)
    set p3 $ClusterCenters($k)
    set V1 [vecsub $p2 $p1]
    set V2 [vecsub $p3 $p1]
    set N [veccross $V1 $V2]
    set D [vecdot $N $p1]
    return [list $N $D]
}

proc VertexDistance {args} {
    if {[llength $args] != 2} {
	vmdcon -info "Return the distance between two vertex IDs"
	vmdcon -info "Usage: VertexDistance <VertexID1> <VertexID2>"
	vmdcon -info "Use \"C\" as vertex ID for center"
	error 
    }
    set clusters [array names ::CageMatch::ClusterCenters]
    foreach i $args {
	if { [lsearch $clusters $i] ==-1 & $i!="C"} {
	    error "Invalid VertexID"
	}
    }
    return [eval ::CageMatch::MeasureDistance $args]
}

proc ::CageMatch::MeasureDistance {i j} {
    variable ClusterCenters
    variable CapsidCenter
    
    if {$i=="C"} {
	set p1 $CapsidCenter
    } else {
	set p1 $ClusterCenters($i)
    }

    if {$j=="C"} {
	set p2 $CapsidCenter
    } else {
	set p2 $ClusterCenters($j)
    }    
    return [vecdist $p1 $p2]
}

proc VertexAngle {args} {
    if {[llength $args] != 3} {
	vmdcon -info "Return the angle formed between three vertex IDs"
	vmdcon -info "Usage: VertexDistance <VertexID1> <VertexID2> <VertexID3>"
	vmdcon -info "Use \"C\" as vertex ID for center"
	error 
    }
    set clusters [array names ::CageMatch::ClusterCenters]
    foreach i $args {
	if { [lsearch $clusters $i] ==-1 & $i!="C"} {
	    error "Invalid VertexID"
	}
    }
    return [eval ::CageMatch::MeasureAngle $args]
}

proc ::CageMatch::MeasureAngle {i j k} {
    variable ClusterCenters
    variable CapsidCenter

    foreach index [list $i $j $k] {
	if {$index=="C"} {
	    lappend Coords $CapsidCenter
	} else {
	    lappend Coords $ClusterCenters($index)
	}
    }
    lassign $Coords p1 p2 p3
    set v1 [vecnorm [vecsub $p1 $p2]]
    set v2 [vecnorm [vecsub $p3 $p2]]
    set v1dotv2 [vecdot $v1 $v2]
    return [expr 180*acos($v1dotv2)/3.14159265359]
}


proc ::CageMatch::TriangleArea {triangle} {
    variable ClusterCenters

    foreach {i j k} $triangle break 

    set p1 $ClusterCenters($i)
    set p2 $ClusterCenters($j)
    set p3 $ClusterCenters($k)

    set d2 [vecsub $p2 $p3]
    set d3 [vecsub $p1 $p3]
    
    return [expr 0.5*[veclength [veccross $d2 $d3]]]
}

proc ::CageMatch::PyramidVolume {triangle} {
    variable ClusterCenters
    variable CapsidCenter

    set Area [TriangleArea $triangle]
    foreach {i j k} $triangle break 
    set plane [CalcTrianglePlane $i $j $k]
    foreach {ABC D} $plane break
    
    set height [ expr abs([vecdot $ABC $CapsidCenter]- $D)/[veclength $ABC]]

    return [expr ($Area*$height)/3.0]
}

proc RepVolume {} {
    if {![info exists ::CageMatch::TRACETYPE]} {
	error "Running DrawPolyhedron before this is required"
    }
    return [eval ::CageMatch::CapsidVolume $::CageMatch::TRACETYPE]
}
proc ::CageMatch::CapsidVolume {Ttype} {
    set allowedTypes {capsomers pentamers geodesic kites icosahedron kis goldberg}
    if {[lsearch $allowedTypes $Ttype]==-1} {
	error "Volume Calculation is only for the following: $allowedTypes"	
    }
    if {$Ttype=="goldberg"} {set Ttype gfaces}
    if {$Ttype=="kites"} {
	set triangles [SortKiteTriangles ]
    } else {
	set triangles [LocateTriangles $Ttype]
    }
    set sum 0
    foreach t $triangles {set sum [expr $sum + [PyramidVolume $t]]}
    return $sum
}

proc SurfaceArea {} {
    if {![info exists ::CageMatch::TRACETYPE]} {
	error "Running DrawPolyhedron before this is required"
    }
    return [eval ::CageMatch::SurfaceArea $::CageMatch::TRACETYPE]
}

proc ::CageMatch::SurfaceArea {Ttype} {
    if {$Ttype=="goldberg"} {set Ttype gfaces}
    if {$Ttype=="kites"} {
	set triangles [SortKiteTriangles ]
    } else {
	set triangles [LocateTriangles $Ttype]
    }
    set AreaSurf 0
    foreach t $triangles {set AreaSurf [expr $AreaSurf + [TriangleArea $t]]}
    return $AreaSurf
}

proc Sphericity {} {
    if {![info exists ::CageMatch::TRACETYPE]} {
	error "Running DrawPolyhedron before this is required"
    }
    return [eval ::CageMatch::Sphericity $::CageMatch::TRACETYPE]
}
proc ::CageMatch::Sphericity {Ttype} {
    set Volume [CapsidVolume $Ttype]
    set sqrtPI [expr sqrt(3.14159265359)]
    set AreaSurf [SurfaceArea $Ttype]
    set Vol23 [expr pow(6*$sqrtPI*$Volume, 2.0/3.0)]
    set sphericity [expr $Vol23/$AreaSurf]
	       
    return $sphericity
}

proc ::CageMatch::Faceting {{radians 0}} {
    variable KITEAXISTWOFOLD
    variable PentamerIDs
    variable TwofoldIDs
    variable TrifoldIDs
    variable CapsidCenter
    variable ClusterCenters
    variable TRACEICOSA

    if {!$TRACEICOSA} {
	error "This analysis requires icosahedral symmetry"
    }
    lassign [SetupTypes kites 1] indexList neighboursList
    array set neighbours $neighboursList
    foreach i $PentamerIDs {
	foreach j $TrifoldIDs {
	    set vertex2fold [::struct::set intersect $neighbours($i) $neighbours($j)]
	    if {[llength $vertex2fold]> 0} {
		set kitePlanes($i,$j) $vertex2fold
	    }
	}
    }

    set angletypes { 5,l 5,r 5,a 3,l 3,r 3,a}
    foreach atype $angletypes {
	set sum($atype)  0
	set sum2($atype) 0
    }
    set sum5l 0
    set sum5r 0
    set sum5a 0
    set sum3l 0
    set sum3r 0
    set sum3a 0

    set sum5l2 0
    set sum5r2 0
    set sum5a2 0
    set sum3l2 0
    set sum3r2 0
    set sum3a2 0
    
    foreach kiteax [array names kitePlanes] {
	lassign [split $kiteax ,] i j
	lassign $kitePlanes($kiteax) k l
	set pent $ClusterCenters($i)
	set tri  $ClusterCenters($j)
	set two1 $ClusterCenters($k)
	set two2 $ClusterCenters($l)

	#Determine which twoFold vertex is to the right of the plane formed by the trifold, center and pentamer
	set vectors(5) [vecnorm [vecsub $pent $CapsidCenter]]
	set vectors(3) [vecnorm [vecsub $tri  $CapsidCenter]]
	set rlplane_n [vecnorm [veccross $vectors(3) $vectors(5)]]
	set vecPT1 [vecnorm [vecsub $pent $two1]]
	set vecPT2 [vecnorm [vecsub $pent $two2]]	
	set vecTT1 [vecnorm [vecsub $tri  $two1]]
	set vecTT2 [vecnorm [vecsub $tri  $two2]]

	if { [vecdot $rlplane_n $vecPT1] < 0 } {
	    set plane_n(r) [vecnorm [veccross $vecTT1 $vecPT1]]
	    set plane_n(l) [vecnorm [vecinvert [veccross $vecTT2 $vecPT2]]]
	    set rtwo $two1
	    set ltwo $two2
	    
	} else {
	    set plane_n(l) [vecnorm [vecinvert [veccross $vecTT1 $vecPT1]]]
	    set plane_n(r) [vecnorm [veccross $vecTT2 $vecPT2]]
	    set ltwo $two1
	    set rtwo $two2
	}

	#sum of plane vectors
	set plane_n(a) [vecnorm [vecadd $plane_n(l) $plane_n(r)]]
	
	foreach atype $angletypes {
	    lassign [split $atype ,] point side
	    set theta($atype) [expr acos([vecdot $vectors($point) $plane_n($side)])]
	}
	foreach atype $angletypes {
	    set sum($atype)  [expr $sum($atype)  + $theta($atype)   ]
	    set sum2($atype) [expr $sum2($atype) + $theta($atype)**2]
	}

    }
    set N [array size kitePlanes]

    foreach atype $angletypes {
	set sum($atype)  [expr  $sum($atype)/($N)]
	set sum2($atype) [expr $sum2($atype)/($N)]
	set std($atype)  [expr sqrt($sum2($atype)-$sum($atype)**2) ]
    }
    set pi 3.14159265359
    set results {}
    if {$radians} {
	foreach atype $angletypes {lappend results $sum($atype) $std($atype)}
    } else {
	foreach atype $angletypes {lappend results [expr 180*$sum($atype)/$pi] [expr 180*$std($atype)/$pi]}
    }

    return $results
}

# Returns and indexlist of the vertices involved in a given polyhedra
# can additionally return the neighbour list associated with said polyhedra
proc ::CageMatch::SetupTypes {Ttype {retNeighbours 1}} {
    variable PentamerIDs
    variable HexamerIDs
    variable TwofoldIDs
    variable TrifoldIDs
    variable GoldbergIDs
    variable GoldbergPentIDs
    variable GoldbergHexIDs
    variable TwofoldNeighbours
    variable KiteNeighbours
    variable SymmetryNeighbours    
    variable PentNeighbours
    variable HexNeighbours
    variable ClusterNeighbours
    variable HybridNeighbours
    variable GoldbergNeighbours
    variable GoldbergTriNeighbours
    
    switch -regexp $Ttype {
	(pentamers|icosahedron) {set indexList $PentamerIDs
	    set neighbours [array get PentNeighbours]
	}	
	capsomers {set indexList [concat $PentamerIDs $HexamerIDs]
	    set neighbours [array get ClusterNeighbours]
	}
	hexamers {set indexList $HexamerIDs
	    set neighbours [array get HexNeighbours]
	}
	twofold {set indexList $TwofoldIDs
	    set neighbours [array get TwofoldNeighbours]
	}
	kites {set indexList [concat $PentamerIDs $TwofoldIDs $TrifoldIDs]
	    set neighbours [array get KiteNeighbours]
	}
	(triangles|geodesic) {set indexList [concat $PentamerIDs $TwofoldIDs]
	    set neighbours [array get SymmetryNeighbours]
	}
	kis {set indexList [concat $PentamerIDs $HexamerIDs $GoldbergIDs]
	    set neighbours  [array get HybridNeighbours]
	}
	goldberg {set indexList $GoldbergIDs
	    set neighbours  [array get GoldbergNeighbours]
	}
	gfaces {set indexList [concat $GoldbergIDs $GoldbergPentIDs $GoldbergHexIDs]
	    set neighbours  [array get GoldbergTriNeighbours]
	}
	default {
	    error "Unacceptable argument. Acceptable arguments are capsomers, pentamers,icosahedron, hexamers, twofold, kites, geodesic, goldberg or kis"
	}
	
    }
    if {$retNeighbours} {
	return [list $indexList $neighbours]
    } else {
	return $indexList
    }
}

# Returns option list for drawing representation
proc ::CageMatch::SetupDrawing {DrawType} {
    set dtypes [split $DrawType {}]
    if {[lsearch $dtypes "V"]!=-1 || [lsearch $dtypes "v"]!=-1} {
	set drawVertex 1
    } else {
	set drawVertex 0
    }
    if {[lsearch $dtypes "E"]!=-1 || [lsearch $dtypes "e"]!=-1} {
	set drawEdge 1
    } else {
	set drawEdge 0
    }
    if {[lsearch $dtypes "F"]!=-1 || [lsearch $dtypes "f"]!=-1} {
	set drawFill 1
    } else {
	set drawFill 0
    }
    return [list $drawVertex $drawEdge $drawFill]
}

proc ::CageMatch::DrawSphere {index {molid top} {rad 5} {res 25} } {
    variable ClusterCenters
    variable PentamerIDs
    variable HexamerIDs
    variable TwofoldIDs
    variable TrifoldIDs
    variable GoldbergIDs
    variable GoldbergPentIDs
    variable GoldbergHexIDs
    variable VERTEXMATERIAL
    variable PENTAMERCOLOR
    variable HEXAMERCOLOR
    variable TRIFOLDCOLOR
    variable TWOFOLDCOLOR
    variable GOLDBERGCOLOR
    
    if {[lsearch $GoldbergIDs $index]!=-1}  {
    	set color $GOLDBERGCOLOR
    }
    
    if {[lsearch $TwofoldIDs $index]!=-1}  {
	set color $TWOFOLDCOLOR
    } elseif {[lsearch $TrifoldIDs $index]!=-1} {
	set color $TRIFOLDCOLOR
    }

    if {[lsearch $PentamerIDs $index]!=-1 || [lsearch $GoldbergPentIDs $index]!=-1} {
	set color $PENTAMERCOLOR
    } elseif {[lsearch $HexamerIDs $index]!=-1 || [lsearch $GoldbergHexIDs $index]!=-1} {
	set color $HEXAMERCOLOR
    }

    graphics $molid material $VERTEXMATERIAL
    graphics $molid color $color
    graphics $molid sphere $ClusterCenters($index) radius $rad resolution $res
}

proc ::CageMatch::PrintVcolorLegend {} {
    variable PENTAMERCOLOR
    variable HEXAMERCOLOR
    variable TRIFOLDCOLOR
    variable TWOFOLDCOLOR
    variable GOLDBERGCOLOR
    vmdcon -info "Vertices are colored according to their location on the capsid"
    vmdcon -info "Current color scheme is:"
    vmdcon -info "   - Vertices on pentamer centers are $PENTAMERCOLOR"
    vmdcon -info "   - Vertices on hexamer centers are $HEXAMERCOLOR"
    vmdcon -info "   - Vertices on twofold symmetry axis are $TWOFOLDCOLOR"
    vmdcon -info "   - Vertices on trifold symmetry axis are $TRIFOLDCOLOR"
    vmdcon -info "   - All other vertices are $GOLDBERGCOLOR"
    vmdcon -info " "
    vmdcon -info "Capsomer colors take priority over symmetry axis colors, e.g:"
    vmdcon -info "If a vertex is located on both a hexamer center and a twofold"
    vmdcon -info "symmetry axis, it will be colored as a hexamer"    
}

proc ::CageMatch::DrawTriangle {triangle {molid top}} {
    variable ClusterCenters
    variable FACECOLOR
    variable FACEMATERIAL
    foreach {i j k} $triangle break
    graphics $molid material $FACEMATERIAL
    graphics $molid color $FACECOLOR
    graphics $molid triangle $ClusterCenters($i) $ClusterCenters($j) $ClusterCenters($k)
}

proc ::CageMatch::DrawVertices {{Ttype "capsomers"} {molid top} {rad "None"} {res "None"}} {
    variable VERTEXRAD
    variable VERTEXRES

    if { $rad == "None"} {set rad $VERTEXRAD}
    if { $res == "None"} {set res $VERTEXRES}
    set indexList [SetupTypes $Ttype 0]
    set drawList {}
    foreach i $indexList {
	lappend drawList [DrawSphere $i $molid $rad $res]
    }
    return $drawList
}

proc ::CageMatch::DrawEdges {{Ttype "capsomers"} {molid top}} {
    variable ClusterCenters
    variable EDGECOLOR
    variable EDGEMATERIAL
    variable EDGERAD
    variable EDGERES
    foreach {indexList neighbourList} [SetupTypes $Ttype 1] break
    array set neighbours $neighbourList
    set drawn {}
    set drawList {}
    graphics $molid material $EDGEMATERIAL
    graphics $molid color $EDGECOLOR
    foreach i $indexList {
	set nList $neighbours($i)
	set coords1 $ClusterCenters($i)
	foreach j $nList {
	    set A [lsort -integer [list $i $j]]
	    if {[lsearch $drawn $A]!=-1} continue
	    set coords2 $ClusterCenters($j)
	    lappend drawList [graphics $molid cylinder $coords1 $coords2 radius $EDGERAD resolution $EDGERES]
	    lappend drawn $A
	}
    }
    return [list $drawn $drawList]
}

proc ::CageMatch::DrawPyramids {Ttype {molid top} {DrawType "VE"}} {
    variable LastDrawnPolygon
    variable CapsidCenter
    variable ClusterCenters
    variable EDGEMATERIAL
    variable EDGECOLOR
    variable EDGERAD
    variable EDGERES
    
    set polygon [DrawPolygon $Ttype $molid E]
    set indexList [SetupTypes $Ttype 0]
    graphics $molid material $EDGEMATERIAL
    graphics $molid color $EDGECOLOR
    foreach i $indexList {
	lappend polygon [graphics $molid cylinder $ClusterCenters($i) $CapsidCenter radius $EDGERAD resolution $EDGERES]
    }

    set LastDrawnPolygon $polygon
    return $polygon     
}

# Draw given polygon based on the following keywords:
#   - pentamers: Icosahedron, vertices correspond to center pentavalent capsomers
#   - capsomers: Triangular-faced polyhedra, vertices correspond to capsomer centers
#   - triangles: Triangular-faced polyhedra, vertices correspond to symmetry axes
#   - hexamers:  Pentamer outline, vertices correspond to hexavalent capsomers
#   - twofold:   Pentamer outline, vertices correspond to twofold symmetry axes
#   - kites:     Kites polyhedra, vertices correspond to symmetry axes
proc ::CageMatch::DrawPolygon {Ttype {molid top} {DrawType "VE"}} {
    variable LastDrawnPolygon
    variable CLEANPREVIOUS
    variable GOLDBERGCENTER
    
    if {$Ttype == "kites"} {return [DrawKites $molid $DrawType]}
    if {$CLEANPREVIOUS} {CleanLast $molid}
    foreach {drawVertex drawEdge drawFill} [SetupDrawing $DrawType] break
    
    set drawList {}
    if {$Ttype=="goldberg"} {set Ttype2 "gfaces"} else {set Ttype2 $Ttype}
    if {$drawFill} {	
	set triangles [LocateTriangles $Ttype2]
	foreach t $triangles {lappend drawList [DrawTriangle $t $molid]}
    }
    if {$drawEdge} {
	foreach {pair dList} [DrawEdges $Ttype $molid] break
	set drawList [concat $drawList $dList]
    }
    if {$drawVertex} {
	if {$GOLDBERGCENTER} {set Ttype $Ttype2}
	set drawList [concat $drawList [DrawVertices $Ttype $molid]]
    }

    

    set LastDrawnPolygon $drawList
    return $drawList
}

# [LocateTriangles kites] returns excess triangles not needed for
# this representation, this function removes said extra triangles
proc ::CageMatch::SortKiteTriangles {} {
    variable TwofoldIDs
    variable KITEAXISTWOFOLD
    set TriangleList [LocateTriangles kites]
    set NewTriangleList {}
#    puts "original num triangles: [llength $TriangleList]"
    foreach trig $TriangleList {
	set count 0
	set count2 0
	foreach v $trig {
	    if {[lsearch $TwofoldIDs $v]!=-1} {incr count}
	}
	
	if {($count==2 && !$KITEAXISTWOFOLD) || ($count<2 && $KITEAXISTWOFOLD)} {
	    lappend NewTriangleList $trig
	}
    }
#    puts "Number of triangles: [llength $NewTriangleList]"
    return $NewTriangleList
}

proc ::CageMatch::DrawKites {{molid top} {DrawType "VE"}} {
    variable TwofoldIDs
    variable TrifoldIDs
    variable PentamerIDs
    variable LastDrawnPolygon
    variable CLEANPREVIOUS
    if {$CLEANPREVIOUS} {CleanLast $molid}
    foreach {drawVertex drawEdge drawFill} [SetupDrawing $DrawType] break
    
    set drawList {}
    if {$drawFill} {
	set triangles [SortKiteTriangles]
	foreach t $triangles {lappend drawList [DrawTriangle $t $molid]}
    }

    if {$drawEdge} {
	foreach {drawn dList} [DrawEdges kites $molid] break
	foreach pair $drawn d $dList {
	    foreach {i j} $pair break
	    set trifold [if {([lsearch $TrifoldIDs $i]!=-1 || [lsearch $TrifoldIDs $j]!=-1)} {expr 1} {expr 0}]
	    set fivefold [if {([lsearch $PentamerIDs $i]!=-1 || [lsearch $PentamerIDs $j]!=-1)} {expr 1} {expr 0}]
	    if {[lsearch $TwofoldIDs $i]!=-1 && [lsearch $TwofoldIDs $j]!=-1} {
		graphics $molid delete $d
	    } elseif { $fivefold && $trifold}  {
		graphics $molid delete $d
	    } else {
		lappend newdList $d
	    }
	}
	set drawList [concat $drawList $newdList]
    }
    if {$drawVertex} {set drawList [concat $drawList [DrawVertices kites $molid]]}

    set LastDrawnPolygon $drawList
    return $drawList
}

# Deletes the last polyhedron that was drawn if CLEANPREVIOUS is
# set (set by default). If script is sourced before deleting
# last drawn polyhedra, it has to be deleted manually
proc ::CageMatch::CleanLast {{molid top} {ClearList "None"}} {
    variable LastDrawnPolygon
    if {$ClearList == "None"} {
	set ClearList $LastDrawnPolygon
    }
    foreach id $ClearList {graphics $molid delete $id}
}

# Draws the neighbours of a given vertex for a given representation
proc ::CageMatch::DrawNeighbours {index  {Ttype "capsomers"} {molid top}} {
    variable LastDrawnPolygon
    variable CLEANPREVIOUS 
    if {$CLEANPREVIOUS} {CleanLast $molid}
    foreach {indexList neighbourList} [SetupTypes $Ttype 1] break
    array set neighbours $neighbourList
    set drawList [DrawSphere $index $molid]
    foreach i $neighbours($index) {lappend drawList [DrawSphere $i $molid]}
    set LastDrawnPolygon $drawList
    return $drawList
}

# wrapper function for RunPolygon, used when setting trace
proc ::CageMatch::TracerFunc {name element op} {
    variable TRACETYPE
    variable TRACEDRAW
    variable TRACESELECTION
    variable TRACEMOLID
    global vmd_frame
    RunPolygon $TRACETYPE $TRACEDRAW $TRACEMOLID $vmd_frame($TRACEMOLID) $TRACESELECTION
    return
}


proc ::CageMatch::EnableTrace {Ttype {drawtype "VE"} {molid top} {selection "name CA" } {icosa 1}} {
    variable TRACETYPE
    variable TRACEDRAW
    variable TRACESELECTION
    variable TRACEMOLID
    variable TRACEENABLED
    variable TRACEICOSA
    variable INITCLUSTER
    
    global vmd_frame
    
    graphics $molid delete all
    if {$molid=="top"} {set molid [molinfo top]}
    if {$icosa!= $TRACEICOSA} {set INITCLUSTER 0}
    set TRACETYPE $Ttype
    set TRACEDRAW $drawtype
    set TRACESELECTION $selection
    set TRACEMOLID $molid
    set TRACEICOSA $icosa
    if {![info exists TRACEENABLED]} {set TRACEENABLED 0}
    if {$TRACEENABLED} {DisableTrace} else {set TRACEENABLED 1}
    TracerFunc 0 0 0
    trace add variable vmd_frame($TRACEMOLID) write ::CageMatch::TracerFunc
}

proc ::CageMatch::DisableTrace {} {
    variable TRACETYPE
    variable TRACEDRAW
    variable TRACESELECTION
    variable TRACEMOLID
    
    global vmd_frame
    graphics $TRACEMOLID delete all
    trace remove variable vmd_frame($TRACEMOLID) write ::CageMatch::TracerFunc
}

proc ::CageMatch::ColorChangeTrace {name element op} {
    variable TRACETYPE 
    variable TRACEDRAW
    variable TRACESELECTION
    variable TRACEMOLID
    variable TRACEENABLED
    variable TRACEICOSA
    
    if {![info exists TRACEENABLED]} {set TRACEENABLED 0}
    if {$TRACEENABLED} {
	EnableTrace $TRACETYPE $TRACEDRAW $TRACEMOLID $TRACESELECTION $TRACEICOSA
	#PrintVcolorLegend
    }
    
}


proc ::CageMatch::ExtractPoly {} {
    variable CapsidCenter
    variable ClusterCenters
    variable PentamerIDs
    variable HexamerIDs
    variable TrifoldIDs
    variable TwofoldIDs
    variable GoldbergIDs
    variable TRACETYPE 
    variable TRACEDRAW
    variable TRACESELECTION
    variable TRACEMOLID
    variable TRACEENABLED

    if {!$TRACEENABLED} {error "Enable a polyhedra trace to be able to extract it"} 
    lassign  [SetupTypes $TRACETYPE 1] indexList neighbourList
    array set neighbours $neighbourList
    set Natoms [expr 1 +[llength $indexList]]
    
    set Pids [::struct::set intersect $PentamerIDs $indexList]
    set Hids [::struct::set intersect $HexamerIDs $indexList]
    set Xids [::struct::set intersect $TwofoldIDs $indexList]
    set Tids [::struct::set intersect $TrifoldIDs $indexList]
    set Sids [::struct::set intersect $GoldbergIDs $indexList]

    set Sids [::struct::set difference $Sids $Tids]
    set Sids [::struct::set difference $Sids $Xids]
    if {[llength $Hids] !=0} {
	if {[llength [::struct::set difference $Hids $Xids]]==0} {set Xids {}}
	if {[llength [::struct::set difference $Hids $Tids]]==0} {set Tids {}}
    }
    set count 1
    set Vnames {P H X T S}
    # puts "Pids $Pids"
    # puts "Hids $Hids"
    # puts "Xids $Xids"
    # puts "Tids $Tids"
    # puts "Sids $Sids"
    
    foreach Ilist [list $Pids $Hids $Xids $Tids $Sids] vtype $Vnames  {
	
	foreach id $Ilist {
	    set atomid2vertexid($count) $id
	    set vertexid2atomid($id) $count
# 	    puts "$count $atomid2vertexid($count)"
	    lappend AtomIDList($vtype) $count
	    incr count
	}
	
    }

    set newmol [mol new atoms $Natoms]
    # puts [array get AtomIDList]
    set Vnames [::struct::set intersect $Vnames [array names AtomIDList]]
    foreach vtype $Vnames {	
	puts "$vtype [llength $AtomIDList($vtype)]"
	set AtomSelections($vtype) [atomselect $newmol "index $AtomIDList($vtype)"]
	$AtomSelections($vtype) set name $vtype
	$AtomSelections($vtype) set resname $vtype
	$AtomSelections($vtype) set chain $vtype
	set segnames {}
	set i 1
	foreach p [$AtomSelections($vtype) list] {
	    lappend segnames ${vtype}${i}
	    incr i
	}
	$AtomSelections($vtype) set segname $segnames
    }
#     puts "got here"
    
    
    set nf [molinfo $TRACEMOLID get numframes]
    mol top $TRACEMOLID
    set sel1 [atomselect $newmol "index 0"]
    $sel1 set {name chain resname segname} {{C C C C}}    

#    puts [array get atomid2vertexid]
    for {set i 0} {$i < $nf} {incr i} {
	animate dup $newmol
	animate goto $i
	$sel1 frame $i
	$sel1 set {x y z} [list $CapsidCenter]
	display update
	foreach vtype $Vnames {
	    $AtomSelections($vtype) frame $i
	    set coords {}
	    foreach p [$AtomSelections($vtype) list] {
		lappend coords $ClusterCenters($atomid2vertexid($p))
	    }
	    $AtomSelections($vtype) set {x y z} $coords
	}
	

    }

    for {set i 1} {$i <$Natoms} {incr i} {
	set sel [atomselect $newmol "index $i"]
	$sel setbonds [list [lmap x $neighbours($atomid2vertexid($i)) {expr $vertexid2atomid($x)}]]
	$sel delete
    }
    return [ array get atomid2vertexid ]
}

proc SavePoly {args} {
    if {[llength $args] !=1} {
	puts "Save current polyhedral representation info"
	puts "Usage: SavePoly <output>"
	error ""
    }
    return [eval ::CageMatch::SaveVertexinfo $args]
}

proc ::CageMatch::SaveVertexinfo {output} {
    # Vertex ID variables:
    variable PentamerIDs
    variable HexamerIDs
    variable TrifoldIDs
    variable TwofoldIDs
    variable GoldbergIDs
    variable GoldbergPentIDs
    variable GoldbergHexIDs
    
    # Arrays with vertex info:
    variable ClusterMembers
    variable ClusterCenters
    variable ClusterSelections

    # Arrays with Neighbour info:
    variable ClusterNeighbours  
    variable PentNeighbours  
    variable HexNeighbours
    variable SymmetryNeighbours
    variable KiteNeighbours
    variable TwofoldNeighbours
    variable HybridNeighbours
    variable GoldbergNeighbours
    variable GoldbergTriNeighbours
    
    # Capsid info:
    variable CageCenterSelection
    variable CapsidCenter
    variable CAPSOMERNUM
    variable Tnumber

    # Graphical Representation variables:
    variable FACECOLOR 
    variable EDGECOLOR 
    variable FACEMATERIAL 
    variable EDGEMATERIAL 
    variable VERTEXMATERIAL 
    variable KITEAXISTWOFOLD
    variable PENTAMERCOLOR 
    variable HEXAMERCOLOR 
    variable TRIFOLDCOLOR 
    variable TWOFOLDCOLOR 
    variable GOLDBERGCOLOR 
    variable GOLDBERGCENTER 
    variable VERTEXRAD 
    variable VERTEXRES 
    variable EDGERAD 
    variable EDGERES 


    variable CLUSTERBY 
    variable NUMBERMEMBERS
    variable KEEPSELECTIONS 
    variable CLEANPREVIOUS 
    variable CURRENTSELECTION 
    variable LastDrawnPolygon 

    # Variables for trace:
    variable TRACETYPE
    variable TRACEDRAW
    variable TRACESELECTION 
    variable TRACEMOLID 
    variable TRACEENABLED 
    variable TRACEICOSA
    variable TRACECOLOR
    variable CAGESEL

    set fp [open $output w+]
    try {
	set arrayvars {
	    ClusterMembers
	    ClusterSelections
	    ClusterNeighbours  
	    PentNeighbours  
	    HexNeighbours
	    SymmetryNeighbours
	    KiteNeighbours
	    TwofoldNeighbours
	    HybridNeighbours
	    GoldbergNeighbours
	    GoldbergTriNeighbours
	}
	
	foreach ntype $arrayvars {
	    puts $fp "array unset ::CageMatch::$ntype *"
	}
	
	puts $fp "set ::CageMatch::CAPSOMERNUM $CAPSOMERNUM"

	if {$TRACEICOSA} {puts $fp "set ::CageMatch::Tnumber $Tnumber"}

	puts $fp "set ::CageMatch::CAGESEL {$CAGESEL}"
	puts $fp "vmdcon -info \"loading Vertex IDs ...\""
	puts $fp "set ::CageMatch::PentamerIDs [list $PentamerIDs]"
	puts $fp "set ::CageMatch::HexamerIDs  [list $HexamerIDs]"
	puts $fp "set ::CageMatch::TrifoldIDs  [list $TrifoldIDs]"
	puts $fp "set ::CageMatch::TwofoldIDs  [list $TwofoldIDs]"
	puts $fp "set ::CageMatch::GoldbergIDs   [list $GoldbergIDs]"
	puts $fp "set ::CageMatch::GoldbergPentIDs [list $GoldbergPentIDs]"
	puts $fp "set ::CageMatch::GoldbergHexIDs [list $GoldbergHexIDs]"
	
	puts $fp "vmdcon -info \"loading cluster members ...\""
	puts $fp "array unset ::CageMatch::ClusterMembers *"
	foreach {i segnames} [array get ClusterMembers] {
	    puts $fp "set ::CageMatch::ClusterMembers($i) [list $ClusterMembers($i)]"
	}

	puts $fp "vmdcon -info \"loading neighbour info ...\""
	set neighbourTypes {
	    ClusterNeighbours
	    PentNeighbours
	    KiteNeighbours
	    HybridNeighbours
	    SymmetryNeighbours
	}
	foreach i $PentamerIDs {
	    foreach ntype $neighbourTypes {
		try { puts $fp "set ::CageMatch::${ntype}($i) [list [set ${ntype}($i)]]"} finally {continue}
	    }
	    # puts $fp "set ::CageMatch::ClusterNeighbours($i) $ClusterNeighbours($i)"
	    # puts $fp "set ::CageMatch::PentNeighbours($i) $PentNeighbours($i)"
	    # try {puts $fp "set ::CageMatch::KiteNeighbours($i) $KiteNeighbours($i)"}
	    # try {puts $fp "set ::CageMatch::GoldbergNeighbours($i) $GoldbergNeighbours($i)"}
	    # try {puts $fp "set ::CageMatch::SymmetryNeigbours($i) $SymmetryNeigbours($i)"}
	    
	}

	set neighbourTypes {ClusterNeighbours HexNeighbours HybridNeighbours}
	foreach i $HexamerIDs {
	    foreach ntype $neighbourTypes {
		try { puts $fp "set ::CageMatch::${ntype}($i) [list [set ${ntype}($i)]]"} finally {continue}
	    }
	}

	set neighbourTypes {TwofoldNeighbours KiteNeighbours SymmetryNeighbours}    	
	foreach i $TwofoldIDs {
	    foreach ntype $neighbourTypes {
		try { puts $fp "set ::CageMatch::${ntype}($i) [list [set ${ntype}($i)]]"} finally {continue}
	    }
	}
	
	set neighbourTypes {KiteNeighbours}    	
	foreach i $TrifoldIDs {
	    foreach ntype $neighbourTypes {
		try { puts $fp "set ::CageMatch::${ntype}($i) [list [set ${ntype}($i)]]"} finally {continue}
	    }
	}

	set neighbourTypes {HybridNeighbours GoldbergNeighbours GoldbergTriNeighbours}    	
	foreach i [concat $GoldbergIDs $GoldbergPentIDs $GoldbergHexIDs] {
	    foreach ntype $neighbourTypes {
		try { puts $fp "set ::CageMatch::${ntype}($i) [list [set ${ntype}($i)]]"} finally {continue}
	    }
	}


	puts $fp "vmdcon -info \"loading graphical representation variables\""
	set colors {
	    PENTAMERCOLOR 
	    HEXAMERCOLOR 
	    TRIFOLDCOLOR 
	    TWOFOLDCOLOR 
	    GOLDBERGCOLOR
	}
	puts $fp "set ::CageMatch::TRACECOLOR 0"	
	# foreach col $colors {
	#     puts $fp "trace remove variable ::CageMatch::${col} write ::CageMatch::ColorChangeTrace"
	# }
	set graphvars {
	    FACECOLOR 
	    EDGECOLOR 
	    FACEMATERIAL 
	    EDGEMATERIAL 
	    VERTEXMATERIAL 
	    KITEAXISTWOFOLD
	    PENTAMERCOLOR 
	    HEXAMERCOLOR 
	    TRIFOLDCOLOR 
	    TWOFOLDCOLOR 
	    GOLDBERGCOLOR 
	    GOLDBERGCENTER 
	    VERTEXRAD 
	    VERTEXRES 
	    EDGERAD 
	    EDGERES 
	}
	foreach ntype $graphvars {
	    puts $fp "set ::CageMatch::${ntype} {[set ${ntype}]}"
	}
	puts $fp "set ::CageMatch::TRACECOLOR 1"
	# foreach col $colors {
	#     puts $fp "trace add variable ::CageMatch::${col} write ::CageMatch::ColorChangeTrace"
	# }
	puts $fp "vmdcon -info \"loading trace variables\""
	set tracevars { TRACETYPE TRACEDRAW TRACESELECTION TRACEMOLID TRACEENABLED TRACEICOSA CLUSTERBY}
	foreach ntype $tracevars {
	    puts $fp "set ::CageMatch::${ntype} {[set ${ntype}]}"
	}

	variable KEEPSELECTIONS 
	variable CLEANPREVIOUS 
	variable CURRENTSELECTION

	puts $fp "set ::CageMatch::KEEPSELECTIONS $KEEPSELECTIONS"
	puts $fp "set ::CageMatch::CLEANPREVIOUS $CLEANPREVIOUS"
	puts $fp "set ::CageMatch::CURRENTSELECTION {$CURRENTSELECTION}"
	puts $fp "set ::CageMatch::INITCLUSTER 1"
	if {$KEEPSELECTIONS} {
	    puts $fp  "vmdcon -info \"Making atomselections ...\""
	    puts $fp "::CageMatch::SelectCluster $TRACEMOLID now {$TRACESELECTION}"
	} 
	puts $fp "vmdcon -info \"Drawing polyhedron\""
	puts $fp "DrawPolyhedron $TRACETYPE"
    } finally {
	close $fp
    }
}

proc LoadPoly {args} {
    if {[llength $args] !=1} {
	puts "Load Polyhedral representation "
	puts "Usage: LoadPoly <polyhedron file>"
	error ""
    }
    set output [lindex $args 0]
    source $output
}

if {0} {
    proc Time_commands {script} {
	set start [clock milliseconds]
	uplevel $script
	set end [clock milliseconds]
	return [expr {$end - $start}]
    }
}
