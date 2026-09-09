# cagematch.tcl --
# Developed by Santiago Antolinez
# Lab of Dr. Jodi A. Hadden-Perilla (jhadden@udel.edu)
 
package require struct::list
package require struct::set

package provide cagematch 1.0

set clusdir [file dirname [file normalize [info script]]]

proc InfoCageMatch {} {
    vmdcon -info "The CageMatch plugin is designed geometric analysis of macromolecular"
    vmdcon -info "nanocages based on fitting polyhedral surfaces to the structure. "
    vmdcon -info ""
    vmdcon -info "Available functions include:"
    vmdcon -info "- DrawPolyhedron: Perform vertex detection clustering on user-defined atomselection"
    vmdcon -info "                  to map segnames/fragments to local symmetry axes and draw"
    vmdcon -info "                  specified polyhedron."
    vmdcon -info "- ViewClusterPoints: Visualize points (atomselection centers) to be used as starting"
    vmdcon -info "                     sets for vertex detection clustering."
    vmdcon -info "- ViewClusterMembers: Generate graphical representation of all the segnames/fragments"
    vmdcon -info "                      associated with given vertex IDs."
    vmdcon -info "- RedefineVertices: Recalculate chains defining vertices based on given"
    vmdcon -info "                    atomselection and current vertex positions."
    vmdcon -info "- Member2Vertex: Return list of vertex IDs associated with given segnames/fragments."
    vmdcon -info "- Vertex2Member: Return list of segnames/fragments associated with given vertex IDs."
    vmdcon -info "- SavePolyhedron: Write current vertex definitions and polyhedron connectivity to file."
    vmdcon -info "- LoadPolyhedron: Read vertex definitions and polyhedron connectivity from file"
    vmdcon -info "- PolyhedronNet: Generate 2D Goldberg polyhedron net projection."
    vmdcon -info "- SurfaceArea: Return surface area of current polyhedron."
    vmdcon -info "- Volume: Return volume of current polyhedron."
    vmdcon -info "- Sphericity: Return sphericity of current polyhedron."
    vmdcon -info "- VertexDistance: Return distance between two given vertexIDs"
    vmdcon -info "- VertexAngle: For three given vertex IDs i, j, and k, return the angle"
    vmdcon -info "               between the vector j-i and the vector j-k."
    vmdcon -info "- Faceting: Return the average protrusion angle for icosahedral symmetry axes"
    vmdcon -info "            (the angle between kite-plane normal and the respective local"
    vmdcon -info "            symmetry axis, averaged over all 60 kites)."
    vmdcon -info "- SetVertexColors: Modify vertex color legend."
    vmdcon -info "- StopPolyhedron: Stop updating polyhedron in real time."
    vmdcon -info "- InfoCageMatch: Print this help text."
    vmdcon -info ""
    error ""
}

proc __VCMUsage__ {} {
    vmdcon -info "Generate graphical representation of all the segnames/fragments associated"
    vmdcon -info "with the given vertex IDs."
    vmdcon -info "Usage: ViewClusterMembers <VertexID list> \[options\]"
    vmdcon -info ""
    vmdcon -info "Options are:"
    vmdcon -info "-mol <molid>     -- Molid. Default: top."
    vmdcon -info "-rep <rep_style> -- Rendering method. Defaults to current default method."
    vmdcon -info "-sel <selection> -- Additional atomselection defining graphical"
    vmdcon -info "                    representation. Default: all."
    vmdcon -info "-color <coloring_method> -- Coloring method. Defaults to current default"
    vmdcon -info "                            color."
    vmdcon -info "-material <material_name> -- Material setting. Defaults to current default"
    vmdcon -info "                             material."
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

proc __VCPUsage__ {} {
    vmdcon -info "Visualize points (center of atomselections) to be used as starting sets for"
    vmdcon -info "vertex detection clustering. "
    vmdcon -info "Usage: ViewClusterPoints <atomselection> \[options\]  "
    vmdcon -info ""
    vmdcon -info "Options are: "
    vmdcon -info "-mol <molid>         -- Molid for atomselection. Default: top."
    vmdcon -info "-cagesel <selection> -- Atomselection defining the cage. Default: protein."
    vmdcon -info "-clusterby <segname/fragment> -- Unique chain identifier used in vertex"
    vmdcon -info "                                 detection clustering."
    vmdcon -info "-color <color>       -- sphere color. Default: black."
    vmdcon -info "-rad <radius>        -- sphere radius. Default: 4."
    vmdcon -info "-res <resolution>    -- sphere resolution. Default: 20."
    vmdcon -info "-drawmol <molid>     -- Molid on which to draw. Default: top."
    vmdcon -info "-noerase             -- Don't erase currently drawn graphics"
    vmdcon -info ""
    error ""

}

proc ViewClusterPoints {args} {
    if {[llength $args]==0} {
	__VCPUsage__
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

    set flag [lsearch $args "-drawmol"]
    if {$flag != -1} {
	set drawmolid [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set drawmolid top
    }

    set flag [lsearch $args "-clusterby"]
    if {$flag != -1} {
	set clusterby [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set clusterby $::CageMatch::CLUSTERBY
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
    set flag [lsearch $args "-noerase"]
    if {$flag != -1} {
	set erase 0
	set args [lreplace $args $flag $flag]
    } else {
	set erase 1	
    }
    
    set all [atomselect $molid "$cagesel"]
    set segNames [lsort -unique [$all get $clusterby]]
    $all delete
    if {[llength $args]>0 || ($clusterby!="segname" && $clusterby!="fragment")} {
	if {[llength $args]>0} {vmdcon -err  "Unrecognized option: $args"}
	__VCPUsage__
    }

    if {$erase} {graphics $drawmolid delete all}
    graphics $drawmolid color $color
    foreach seg $segNames {
    	set sel [atomselect $molid "$clusterby $seg and ($selection)" ]
        graphics $drawmolid sphere   [measure center $sel] radius $rad resolution $res
    	$sel delete
    }

    
}

proc StopPolyhedron {args} {
    if {[llength $args] != 1 || ( $args != 1 && $args !=0)} {
	vmdcon -info "Stop updating polyhedron in real time. "
	vmdcon -info "Usage: StopPolyhedron <delpoly>"
	vmdcon -info ""
	vmdcon -info " <delpoly> options are:"
	vmdcon -info "   1 -- Delete last drawn polyhedron"
	vmdcon -info "   0 -- Keep last drawn polyhedron"
	vmdcon -info ""
	error ""
    }

    if {![info exists ::CageMatch::TRACEENABLED]} {
	vmdcon -err " No trace enabled"
	error ""
    }
    
    set TRACEMOLID $::CageMatch::TRACEMOLID
    if {$TRACEMOLID=="top"} {set TRACEMOLID [molinfo top]}
    set TRACEENABLED $::CageMatch::TRACEENABLED

    if {$args} {
	::CageMatch::CleanLast $TRACEMOLID
	uplevel {trace remove variable vmd_pick_graphics write ::CageMatch::PickPointTracer}
    }
    
    if {$TRACEENABLED} {
	uplevel {trace remove variable vmd_frame($::CageMatch::TRACEMOLID) write ::CageMatch::TracerFunc}
	set ::CageMatch::TRACEENABLED 0
    }
    if {$::CageMatch::TRACECOLOR} {set ::CageMatch::TRACECOLOR 0}
    return
}

proc __DrawPolyhedronUsage__ {{fromfile 0}} {
    if {$fromfile} {
	vmdcon -info "Load Vertex information from file."
	vmdcon -info "Usage: LoadPolyhedron <polyhedron file> \[options\]"
	vmdcon -info ""
	vmdcon -info "Options are:"
	vmdcon -info "-mol <molid>     -- Cage molid. Default: top."
	vmdcon -info "-poly <polyhedron> -- Polyhedron to draw. Default: geodesic."
	vmdcon -info "-draw <VEF>      -- Combination of strings V E F determines whether to draw"
	vmdcon -info "                    (V)ertices, (E)dges, and/or (F)aces. Default: VE"
	vmdcon -info "-gcenters <on/off> -- Draw face centers for the Goldberg polyhedron. Default: off."
	vmdcon -info ""    
    } else {
	vmdcon -info "Perform vertex detection clustering on user-defined atomselection to map"
	vmdcon -info "segnames/fragments to local symmetry axes and draw specified polyhedron."
	vmdcon -info "Usage: DrawPolyhedron <polyhedron> \[options\]"
	vmdcon -info ""
    }
    vmdcon -info "Available polyhedra:"
    vmdcon -info "icosahedron  -- Regular icosahedron. Vertices represent five-fold"
    vmdcon -info "                icosahedral symmetry axes."
    vmdcon -info "triangulated -- Pentakis icosidodecahedron. Vertices represent five-fold"
    vmdcon -info "                and two-fold icosahedral symmetry axes."
    vmdcon -info "kites        -- Disdyakleetope triacontahedron. Vertices represent the five-fold,"
    vmdcon -info "                two-fold, and three fold icosahedral symmetry axes."
    vmdcon -info "geodesic     -- Triangular-faced polyhedron. Vertices represent capsomer centers."
    vmdcon -info "goldberg     -- Polyhedron composed of pentagonal and hexagonal faces. Dual of"
    vmdcon -info "                the geodesic polyhedron. Vertices represent the three-fold"
    vmdcon -info "                conjunction of capsomers. "
    vmdcon -info "kleetope     -- Triangular-faced polyhedron. Kis of the Goldberg polyhedron."
    vmdcon -info "                Vertices represent the centers and three-fold conjunctions of"
    vmdcon -info "                capsomers."
    vmdcon -info ""
    if {!$fromfile} {
	vmdcon -info "Options (default values mentioned are for the first invocation,"
	vmdcon -info "consecutive invocations default to previously set values):"
	vmdcon -info ""
	vmdcon -info "-mol <molid>     -- Molid on which to draw the polyhedron. Default: top"
	vmdcon -info "-draw <VEF>      -- Combination of strings V E F determines whether to draw"
	vmdcon -info "                    (V)ertices, (E)dges, and/or (F)aces. Default: VE"
	vmdcon -info "-clustersel <selection> -- Atomselection used in vertex detection clustering. Default: name CA."
	vmdcon -info "-recalc          -- Force vertex detection clustering."
	vmdcon -info "-noicosa         -- No icosahedral symmetry present, disables use of"
	vmdcon -info "                    icosahedron, kites, and triangulated polyhedra."
	vmdcon -info "-icosa           -- Icosahedral symmetry present (default)"
	vmdcon -info "-cagesel <selection> -- Atomselection defining the cage. Default: protein."
	vmdcon -info "-clusterby <segname/fragment> -- Unique chain identifier used in vertex"
	vmdcon -info "                                 detection clustering."
	vmdcon -info "-clustersizes <list>   -- List of containing the number of elements per cluster allowed"
	vmdcon -info "                          when performing vertex detection clustering. Default: {5 6}."
	vmdcon -info "-skiprefine <bool>     -- Skip vertex definition refinement. Default: 0 (don't skip)."
	vmdcon -info "-refinesel <selection> -- Atomselection used for refining vertex definitions. Default: name CA."
	vmdcon -info "-gcenters <on/off> -- Draw face centers for the Goldberg polyhedron. Default: off."
	vmdcon -info ""
    }
    error ""
}

proc DrawPolyhedron {args} {
    if {![llength $args]} {
	__DrawPolyhedronUsage__
    }

    set Ttype [lindex $args 0]
    set args [lreplace $args 0 0]
    set allowedTypes {geodesic pentamers triangulated triangles kites twofold hexamers icosahedron goldberg kleetope}

    set flag [lsearch $args "-fromfile"]
    if { $flag != -1} {
	set fromfile 1 
	set args [lreplace $args $flag $flag]
    } else {
	set fromfile 0
    }
    if {[lsearch $allowedTypes $Ttype]==-1} {
	vmdcon -err "Unrecognized option: $Ttype"
	__DrawPolyhedronUsage__	$fromfile
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
	    __DrawPolyhedronUsage__ $fromfile
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
	set midflag 1
    } else {
	set molid $::CageMatch::TRACEMOLID
	set midflag 0
    }

    set flag [lsearch $args "-clustersel"]
    if {$flag != -1} {
	set selection [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set selection $::CageMatch::TRACESELECTION
    }

    set flag [lsearch $args "-clusterby"]
    if {$flag != -1} {
	if {$fromfile} {__DrawPolyhedronUsage__	$fromfile}
	set clusterby [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set clusterby $::CageMatch::CLUSTERBY
    }

    if { $clusterby!="segname" && $clusterby!="fragment"} {
	__DrawPolyhedronUsage__ $fromfile
    }

    if {$clusterby != $::CageMatch::CLUSTERBY} {
	set ::CageMatch::INITCLUSTER 0
    }
    
    set ::CageMatch::CLUSTERBY $clusterby

    set flag [lsearch $args "-clustersizes"]
    if {$flag != -1} {
	if {$fromfile} {__DrawPolyhedronUsage__	$fromfile}
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
	if {$fromfile} {__DrawPolyhedronUsage__	$fromfile}
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
	if {$fromfile} {__DrawPolyhedronUsage__	$fromfile}
	set args [lreplace $args $flag $flag]
	set  ::CageMatch::INITCLUSTER 0
	if {!$midflag} {set molid top}
    }
    
    set flag1 [lsearch $args "-icosa"]
    set flag2 [lsearch $args "-noicosa"]

    if { $flag1 != -1 && $flag2 != -1} {
	__DrawPolyhedronUsage__ $fromfile
    } elseif {$flag2 != -1} {
	if {$fromfile} {__DrawPolyhedronUsage__	$fromfile}
	set args [lreplace $args $flag2 $flag2]
	set icosa 0
    } elseif {$flag1 != -1} {
	if {$fromfile} {__DrawPolyhedronUsage__	$fromfile}
	set args [lreplace $args $flag1 $flag1]
	set icosa 1
    } else {
	set icosa $::CageMatch::TRACEICOSA
    }

    set flag [lsearch $args "-skiprefine"]
    if {$flag != -1} {
	if {$fromfile} {__DrawPolyhedronUsage__	$fromfile}
	set skipref [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set skipref $::CageMatch::SKIPREFINE
    }
    if {$skipref != $::CageMatch::SKIPREFINE} {
	set  ::CageMatch::INITCLUSTER 0
    }
    set ::CageMatch::SKIPREFINE $skipref

    set flag [lsearch $args "-refinesel"]
    if {$flag != -1} {
	if {$fromfile} {__DrawPolyhedronUsage__	$fromfile}
	set refinesel [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    } else {
	set refinesel $::CageMatch::REFINESEL
    }

    if {$refinesel != $::CageMatch::REFINESEL} {
	set ::CageMatch::INITCLUSTER 0	
    }
    set ::CageMatch::REFINESEL $refinesel
   
    if {!$icosa && ( $Ttype =="triangulated" || $Ttype == "kites" || $Ttype =="pentamers" ||$Ttype =="icosahedron") } {
	__DrawPolyhedronUsage__ $fromfile
    }
    if {$icosa != $::CageMatch::TRACEICOSA} {
	set  ::CageMatch::INITCLUSTER 0
    }

    if {!$::CageMatch::TRACECOLOR} {set ::CageMatch::TRACECOLOR 1}
    if {[llength $args] >0} {
	vmdcon -err "Unrecognized option: $args"
	__DrawPolyhedronUsage__ $fromfile
    }
    
    vmdcon -info "Drawing polyhedron $Ttype with options:"
    vmdcon -info "     -draw: $drawType"
    vmdcon -info "     -mol: $molid"
    vmdcon -info "     -clustersel: $selection"
    vmdcon -info "     -cagesel:  $cagesel"
    vmdcon -info "     -clusterby: $clusterby"
    vmdcon -info "     -refinesel: $refinesel"
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
    variable Capsomers2Goldberg
    
    # Arrays with vertex info:
    variable ClusterMembers
    variable ClusterCenters
    variable ClusterSelections
    variable PickPointArr
    variable keysGoldberg
    
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
    variable FACEMATERIAL AOChalky
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

    variable CleanSelType allvertex
    variable CLUSTERBY segname
    variable NUMBERMEMBERS {5 6}
    variable KEEPSELECTIONS 1
    variable CLEANPREVIOUS 1
    variable CURRENTSELECTION ""
    variable REFINESEL "name CA"
    variable SKIPREFINE 0
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
    if {[info exists ctrace]} {unset ctrace}
    
    trace add variable TRACECOLOR write ::CageMatch::ToggleColorTrace

    # Variables for saving vertex information
    variable ARRAYVARS {
	ClusterMembers
	ClusterCenters
	ClusterSelections
	PickPointArr
	keysGoldberg
	ClusterNeighbours  
	PentNeighbours  
	HexNeighbours
	SymmetryNeighbours
	KiteNeighbours
	TwofoldNeighbours
	HybridNeighbours
	GoldbergNeighbours
	GoldbergTriNeighbours
	Capsomers2Goldberg
    }
    
    variable NOSAVE {
	ClusterSelections
	ClusterCenters
	CapsidCenter
	CageCenterSelection
	LastDrawnPolygon
	INITCLUSTER		 
	PickPointArr
	TRACEMOLID
	TRACECOLOR
	ARRAYVARS
	NOSAVE
	Capsomers2Goldberg
	keysGoldberg
    }
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

# Vertex detection clustering using  $CLUSTERBY (segnames or fragment) to get vertices for polihedra 

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
# Calculates the vertices for each of capsomer, sets the center (according to
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
    return [list $segNames $datapoints]
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
	vmdcon -info "There are [llength $PentamerIDs] pentavalent capsomers"
	vmdcon -info "There are [llength $HexamerIDs] hexavalent capsomers"
	CalcNeighbours
    }
}

# Calculates the neighbour list for each capsomer vertex
# neighbour lists here are used for pentamers,
# geodesic, and hexamers polyhedrons
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
proc ::CageMatch::SymmetryAxis {{molid top} {frame now} {selection "name CA"} {ClusterData "None"}} {
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
    variable keysGoldberg
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

    vmdcon -info "Calculating icosahedral symmetry vertices"
    
    #set NewStart [expr $CAPSOMERNUM +1]
    set NewStart [array size ClusterMembers]
    incr NewStart
    
    set TriangleList [LocateTriangles pentamers]
    set PentSegNames {}
    foreach i $PentamerIDs {set PentSegNames [concat $PentSegNames $ClusterMembers($i)]}

    if {$ClusterData == "None"} {
	set all [atomselect $molid "$CAGESEL"]
	set segNames [lsort -unique [$all get $CLUSTERBY]]
	$all delete
	
	set datapoints {}
	foreach seg $segNames {
	    set sel [atomselect $molid "$CLUSTERBY $seg and ($selection)" frame $frame]
	    lappend datapoints [measure center $sel]
	    $sel delete
	}
    } else {
	lassign $ClusterData segNames datapoints
    }
    set FaceCenters {}
    foreach trig $TriangleList {
	foreach {i j k} $trig break
	lappend FaceCenters [vecscale [expr 1./3.] [vecadd $ClusterCenters($i) $ClusterCenters($j) $ClusterCenters($k)]]
    }

    set count $NewStart
    set TrifoldIDs {}
    set isGoldberg 0
    array unset Vertex2Cluster *
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
	    #set Vertex2Cluster($i,$j,$k) $count
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
	    foreach {i j k} $trig break
	    set key [lsort $clustersegids]
	    if {[info exists keysGoldberg($key)]} {set isGoldberg $keysGoldberg($key)} 
	    if {$isGoldberg} {
		lappend TrifoldIDs $isGoldberg
		set Vertex2Cluster($i,$j,$k) $isGoldberg
		set isGoldberg 0
	    } else {
		set sel [atomselect $molid "($selection) and $CLUSTERBY $clustersegids"]
		set ClusterMembers($count) $clustersegids
		set ClusterCenters($count) [measure center $sel]
		set Vertex2Cluster($i,$j,$k) $count
		lappend TrifoldIDs $count
		$sel delete
		incr count
	    }
	    
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
    array unset Edges2Cluster *
    set isGoldberg 0
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
	    set key [lsort $clustersegids]
	    if {[info exists keysGoldberg($key)]} {set isGoldberg $keysGoldberg($key)} 

	    if {$isGoldberg} {
		lappend TwofoldIDs $isGoldberg
		set Edges2Cluster($name) $isGoldberg
		set isGoldberg 0
	    } else {
		set sel [atomselect $molid "($selection) and $CLUSTERBY $clustersegids"]
		set ClusterMembers($count) $clustersegids
		set ClusterCenters($count) [measure center $sel]
		set Edges2Cluster($name) $count
		lappend TwofoldIDs $count
		$sel delete
		incr count
	    }
	    
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
proc ::CageMatch::GoldbergVertex {{molid top} {frame now} {selection "name CA"} {ClusterData "None"}} {
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
    variable keysGoldberg
    
    variable HybridNeighbours
    variable GoldbergNeighbours
    variable GoldbergTriNeighbours
    variable Capsomers2Goldberg
    
    array unset HybridNeighbours *
    array unset GoldbergNeighbours *
    array unset GoldbergTriNeighbours *
    array unset keysGoldberg *

    vmdcon -info "Calculating goldberg vertices"
    #set NewStart [llength [lsort -unique [concat $PentamerIDs $HexamerIDs $TrifoldIDs $TwofoldIDs]]]
    set NewStart [array size ClusterMembers]
    incr NewStart
    set TriangleList [LocateTriangles geodesic]
    lassign  [SetupTypes geodesic 1] indexList neighbourList

    if {$ClusterData == "None"} {
	set all [atomselect $molid "$CAGESEL"]
	set segNames [lsort -unique [$all get $CLUSTERBY]]
	$all delete

	set datapoints {}
	foreach seg $segNames {
	    set sel [atomselect $molid "$CLUSTERBY $seg and ($selection)" frame $frame]
	    lappend datapoints [measure center $sel]
	    $sel delete
	}
    } else {
	lassign $ClusterData segNames datapoints 
    }
    
    set FaceCenters {}
    foreach trig $TriangleList {
 	foreach {i j k} $trig break
	lappend FaceCenters [vecscale [expr 1./3.] [vecadd $ClusterCenters($i) $ClusterCenters($j) $ClusterCenters($k)]]
    }

    set count $NewStart
    set GoldbergIDs {}
    array unset Vertex2Cluster *
    set isVertexTri 0

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
    	lassign $trig i j k
    	set sel [atomselect $molid "($selection) and $CLUSTERBY $clustersegids"]
    	set ClusterMembers($count) $clustersegids
    	set ClusterCenters($count) [measure center $sel]
	set keysGoldberg([lsort $clustersegids]) $count
    	set Vertex2Cluster($i,$j,$k) $count
    	lappend GoldbergIDs $count
    	$sel delete
    	incr count
    }
    
    # foreach center $FaceCenters trig $TriangleList {
    # 	set clustersegids {}
    # 	set pointids {}
    # 	while {[llength $pointids]<6} {
    # 	    set mindist {}
    # 	    for {set i 0} {$i< [llength $datapoints]} {incr i} {
    # 		set coord [lindex $datapoints $i]
    # 		set dist [vecdist $center $coord]
    # 		if {[lsearch $pointids $i]!=-1} continue
    # 		if {$mindist>$dist || $mindist == {}} {
    # 		    set mindist $dist
    # 		    set minI $i
    # 		}
    # 	    }
    # 	    lappend pointids $minI
    # 	}
    # 	foreach j $pointids {lappend clustersegids [lindex $segNames $j]}
    # 	if { [llength [::struct::set intersect $trig $HexamerIDs]]==3} {
    # 	    foreach k $TrifoldIDs {
    # 		if {[llength [::struct::set intersect $clustersegids $ClusterMembers($k)]]==6} {
    # 		    set isVertexTri $k
    # 		    break
    # 		}
    # 	    }
    # 	}
    # 	lassign $trig i j k
    # 	if {$isVertexTri} {
    # 	    lappend GoldbergIDs $isVertexTri
    # 	    set Vertex2Cluster($i,$j,$k) $isVertexTri
    # 	    set isVertexTri 0
    # 	} else {
    # 	    set sel [atomselect $molid "($selection) and $CLUSTERBY $clustersegids"]
    # 	    set ClusterMembers($count) $clustersegids
    # 	    set ClusterCenters($count) [measure center $sel]
    # 	    set Vertex2Cluster($i,$j,$k) $count
    # 	    lappend GoldbergIDs $count
    # 	    $sel delete
    # 	    incr count
    # 	}
    # }

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

    array unset Capsomers2Goldberg *
    # set the pentamers for Goldberg as the center of all hybrid neighbours,same for hexamers
    set count -1
    foreach i $PentamerIDs {
	set GoldbergTriNeighbours($count) $HybridNeighbours($i)
	set GoldbergNeighbours($count) {}
	set Capsomers2Goldberg($i) $count
	lappend GoldbergPentIDs $count
	incr count -1
    }
    
    foreach i $HexamerIDs {
	set GoldbergTriNeighbours($count) $HybridNeighbours($i)
	set GoldbergNeighbours($count) {}
	set Capsomers2Goldberg($i) $count
	lappend GoldbergHexIDs $count
	incr count -1
    }
    UpdateGoldbergCenters
}


proc __RVUsage__ {} {
    vmdcon -info "Recalculate chains corresponding to given subset of vertices based on"
    vmdcon -info "provided atomselection and the current vertex positions."
    vmdcon -info ""
    vmdcon -info "Usage: RedefineVertices <atomselection>  <vertex_subset>"
    vmdcon -info ""
    vmdcon -info "Allowed options for <vertex_subset>:"
    vmdcon -info ""
    vmdcon -info "pentamers         -- Pentavalent vertices."
    vmdcon -info "hexamers          -- Hexavalent vertices."
    vmdcon -info "threefold         -- Icosahedral threefold symmetry vertices."
    vmdcon -info "twofold           -- Icosahedral twofold symmetry vertices."
    vmdcon -info "geodesic          -- All vertices defining the geodesic polyhedron. "
    vmdcon -info "kites             -- All vertices defining the kites polyhedron."
    vmdcon -info "triangulated      -- All vertices defining the triangulated polyhedron."
    vmdcon -info "kleetope          -- All vertices defining the Kleetope polyhedron."
    vmdcon -info "goldberg          -- All vertices defining the Goldberg polyhedron."
    vmdcon -info "allvertex         -- All vertices."
    vmdcon -info ""
    error ""
}

proc RedefineVertices {args} {

    if {!$::CageMatch::INITCLUSTER} {
	vmdcon -err "Run Drawpolyhedron first to run this function"
	error ""
    }
    set largs [llength $args]
    if {$largs <1 || $largs >2} {__RVUsage__}
    set allowedTypes {geodesic pentamers icosahedron hexamers twofold kites triangulated threefold allvertex goldberg kleetope}

    set selection [lindex $args 0]
    set Ttype [lindex $args 1]
    set molid $::CageMatch::TRACEMOLID
    
    if { [lsearch $allowedTypes $Ttype] == -1} {__RVUsage__}
    ::CageMatch::DetMembFromPos $Ttype $molid now $selection "currentsel"
}

# Update Vertex definitions based on current position of vertices
proc ::CageMatch::DetMembFromPos {{Ttype "allvertex"} {molid top} {frame now} {selection "name CA"} {updatesel "currentsel"}} {
    variable CAGESEL
    variable CLUSTERBY
    variable CURRENTSELECTION
    variable ClusterCenters
    variable ClusterSelections
    variable ClusterMembers

    
    set indexList [SetupTypes $Ttype 0]
    set all [atomselect $molid "$CAGESEL"]
    set segNames [lsort -unique [$all get $CLUSTERBY]]
    $all delete
    
    set datapoints {}
    foreach seg $segNames {
     
    	set sel [atomselect $molid "$CLUSTERBY $seg and ($selection)" frame $frame]
	lappend datapoints [measure center $sel]
    	$sel delete
    }
    
    foreach count $indexList {
	set clustersegids {}
	set pointids {}
	set center $ClusterCenters($count)
	
	while {[llength $pointids]<[llength $ClusterMembers($count)]} {
	    set mindist {}
	    for {set i 0} {$i< [llength $datapoints]} {incr i} {
		if {[lsearch $pointids $i]!=-1} continue
		set coord [lindex $datapoints $i]
		set dist [vecdist $center $coord]
		if {$mindist>$dist || $mindist == {}} {
		    set mindist $dist
		    set minI $i
		}
	    }
	    lappend pointids $minI
	}
	foreach j $pointids {lappend clustersegids [lindex $segNames $j]}
	set oldSegnames $ClusterMembers($count)
	set ClusterMembers($count) $clustersegids
	if {[llength [::struct::set symdiff $oldSegnames $ClusterMembers($count)]] != 0} {
	    vmdcon -info  "Updated Vertex $count chains from $oldSegnames to $clustersegids"
	}
    }

    
    if {$updatesel=="currentsel"} {
	SelectCluster $molid $frame $CURRENTSELECTION $Ttype
	UpdateVertices $Ttype $frame $molid $CURRENTSELECTION
    } elseif {$updatesel!=0} {
	SelectCluster $molid $frame $updatesel $Ttype
	UpdateVertices $Ttype $frame $molid $updatesel
    }
}

# Initializes clusters or updates the centers of vertices involved in a given
# polyhedra representation, then draws said representation
proc ::CageMatch::RunPolygon { Ttype {drawtype "VE"} {molid top} {frame now} {selection "name CA" }} {
    variable INITCLUSTER
    set allowedTypes {geodesic pentamers triangulated triangles kites twofold hexamers icosahedron goldberg kleetope}
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
    variable TRACEICOSA
    variable REFINESEL
    variable SKIPREFINE
    variable Tnumber
    variable HexamerIDs
    set ClusterData [ClusterBySegmentsOpt $molid $frame $selection]
    DistBasedNeighbours
    set Tnumber [expr [llength $HexamerIDs]/10 + 1]
    if {$TRACEICOSA} {
	vmdcon -info "T number is: $Tnumber"
	vmdcon -info ""
    }

    GoldbergVertex $molid $frame $selection $ClusterData
    SymmetryAxis $molid $frame $selection $ClusterData
    
    
    if {$KEEPSELECTIONS} {
	if {$SKIPREFINE} {
	    vmdcon -warn "Skipping refinement step"
	    SelectCluster $molid $frame $selection
	} else {
	    vmdcon -info "Refining Vertex definitions"
	    DetMembFromPos allvertex $molid $frame $REFINESEL $selection
	}
    } else {
	if {!$SKIPREFINE} {
	    vmdcon -info "Refining Vertex definitions"
	    DetMembFromPos allvertex $molid $frame $REFINESEL 0
	}
	
	FindCapsidCenter $molid $frame $selection
    }
    
    set INITCLUSTER 1 
}

# Make the atomselections for each of the vertices
# Atomselections are moved to global namespace so they arent deleted when exiting the proc
proc ::CageMatch::SelectCluster {{molid top} {frame now} {selection "name CA"} {Ttype "allvertex"}} {
    variable ClusterMembers
    variable ClusterSelections
    variable CURRENTSELECTION
    variable CLUSTERBY
    variable CageCenterSelection
    variable CapsidCenter
    variable CAGESEL
    CleanSelections $Ttype
    set CURRENTSELECTION $selection
    set indexList [SetupTypes $Ttype 0]
    foreach i $indexList {
	set ClusterSelections($i) [atomselect $molid "($selection) and $CLUSTERBY $ClusterMembers($i)" frame $frame]
	$ClusterSelections($i) global
    }
    set CageCenterSelection [atomselect $molid "($CAGESEL) and ($selection)" frame $frame]
    set CapsidCenter [measure center $CageCenterSelection]
    $CageCenterSelection global
    
}

# Update the centers for a given polyhedron reprensentation
proc ::CageMatch::UpdateVertices {{Ttype "geodesic"} {frame now} {molid top} {selection "name CA"}} {
    variable ClusterMembers
    variable ClusterCenters
    variable CageCenterSelection
    variable KEEPSELECTIONS
    variable CURRENTSELECTION
    variable CAGESEL
    variable CLUSTERBY

    
 
    if {$KEEPSELECTIONS} {
	if {$CURRENTSELECTION!=$selection} {SelectCluster $molid $frame $selection}
	UpdateSelections $frame $Ttype
    } else {
	set indexList [SetupTypes $Ttype 0]
	foreach i $indexList {
	    set sel [atomselect $molid "$CLUSTERBY $ClusterMembers($i) and ($selection)" frame $frame]
	    set ClusterCenters($i) [measure center $sel]
	    $sel delete	
	}
	FindCapsidCenter $molid $frame $selection
    }
    if {$Ttype=="goldberg" || $Ttype=="allvertices"} {UpdateGoldbergCenters}
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
proc ::CageMatch::UpdateSelections {{frame now} {Ttype "allvertex"} } {
    variable ClusterCenters
    variable ClusterSelections
    variable CapsidCenter
    variable CageCenterSelection

    set indexList [SetupTypes $Ttype 0]
    foreach i  $indexList {
#	if {$i==43} { puts "before updating: $ClusterCenters($i)"}
	$ClusterSelections($i) frame $frame
	set ClusterCenters($i) [measure center $ClusterSelections($i)]
#	if {$i==43} { puts "after updating: $ClusterCenters($i)"}
    }
    $CageCenterSelection frame $frame
    set CapsidCenter [measure center $CageCenterSelection]
}

proc ::CageMatch::CleanSelections {{Ttype "allvertex"}} {
    variable ClusterSelections
    variable CageCenterSelection
    variable CleanSelType
    set CleanSelType $Ttype
    uplevel #0 {

#	puts "$::CageMatch::CleanSelType"
	set indexList [::CageMatch::SetupTypes $::CageMatch::CleanSelType 0]
#	puts "[llength $indexList]"
#	puts "$indexList"
	foreach TemporaryCounter $indexList {
	    if {![info exists ::CageMatch::ClusterSelections($TemporaryCounter)]} {continue}
	    set TemporaryCheck [lsearch [atomselect list] $::CageMatch::ClusterSelections($TemporaryCounter)]
	    if { $TemporaryCheck!=-1} {
#		puts "deleting atomselection for $TemporaryCounter"
		$::CageMatch::ClusterSelections($TemporaryCounter) delete
	    }
	    array unset ::CageMatch::ClusterSelections $TemporaryCounter
	}
	if {[info exists ::CageMatch::CageCenterSelection]} {
	    if {[lsearch [atomselect list] $::CageMatch::CageCenterSelection]!=-1} {
		$::CageMatch::CageCenterSelection delete
	    }
	}
	if {[info exists TemporaryCounter]} {unset TemporaryCounter}
	if {[info exists TemporaryCheck]  } {unset TemporaryCheck}
    }
    
   # array unset ClusterSelections *
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
	vmdcon -info "Return list of segnames/fragments associated with given vertex IDs."
	vmdcon -info "Usage: Vertex2Member <VertexID list>"
	error ""
    }
    return [eval ::CageMatch::Vertex2segname "$args" ]
}

proc ::CageMatch::Vertex2segname {vertexids} {
    variable ClusterMembers
    set results {}
    foreach id $vertexids {
        lassign [array get ClusterMembers $id] name val
	if {$name} {
	    lappend results $val
	} else {
	    error "Value $id is not a vertex ID"
	}
#	lappend results $ClusterMembers($id)
    }
    return $results
}

proc __M2VUsage__ {} {
    vmdcon -info "Return list of vertex IDs associated with given segnames/fragments."
    vmdcon -info "Usage: Member2Vertex <fragment/segname list> [-current]"
    vmdcon -info "  -current -- Only print vertex IDs corresponding to the current polyhedron"
    error ""
}
proc Member2Vertex {args} {
    if {![info exists ::CageMatch::TRACETYPE]} {
	error "Running DrawPolyhedron before this is required"
    }
    set num [llength $args]
    if {$num==0 || $num>2} {__M2VUsage__}

    
    if {$num==1} {
	set Ttype allvertex
    } elseif {[lindex $args 1] != "-current"} {
	__V2MUsage__
    } else {	 
	set Ttype $::CageMatch::TRACETYPE
    }
    set seglist [lindex $args 0]
    return [::CageMatch::Segname2vertex $seglist $Ttype]
}

# Returns the vertex IDs of all the vertices to which the segname belongs
proc ::CageMatch::Segname2vertex {segname {Ttype "geodesic"}} {
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
proc ::CageMatch::LocateTriangles {{Ttype "geodesic"}} {
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


proc VertexDistance {args} {
    if {[llength $args] != 2} {
	vmdcon -info "Return the distance between two vertex IDs"
	vmdcon -info "Usage: VertexDistance <VertexID1> <VertexID2>"
	vmdcon -info "Use \"C\" as vertex ID for center"
	error ""
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
	vmdcon -info "- VertexAngle: For three given vertex IDs i, j, and k, return the angle"
	vmdcon -info "between the vector j-i and the vector j-k."
	vmdcon -info "Usage: VertexDistance <VertexID1> <VertexID2> <VertexID3>"
	vmdcon -info "Use \"C\" as vertex ID for center"
	error ""
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

proc ::CageMatch::PyramidVolumeVertex {triangle} {
    variable ClusterCenters
    variable CapsidCenter
    lassign $triangle i j k 
    set u [vecsub $ClusterCenters($i) $CapsidCenter]
    set v [vecsub $ClusterCenters($j) $CapsidCenter]
    set d [vecsub $ClusterCenters($k) $CapsidCenter]
    
    set uxv [veccross $u $v]
    return [expr 1./6.*abs([vecdot $d $uxv])]
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

proc Volume {} {
    if {![info exists ::CageMatch::TRACETYPE]} {
	error "Running DrawPolyhedron before this is required"
    }
    return [eval ::CageMatch::CapsidVolume $::CageMatch::TRACETYPE]
}
proc ::CageMatch::CapsidVolume {Ttype} {
    set allowedTypes {geodesic pentamers triangulated kites icosahedron kleetope goldberg}
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
    foreach t $triangles {set sum [expr $sum + [PyramidVolumeVertex $t]]}
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

proc __FacetingUsage__ {} {
    vmdcon -info "Return the average protrusion angle for icosahedral symmetry axes ( the"
    vmdcon -info "angle between kite-plane normal and the respective local symmetry axis,"
    vmdcon -info "averaged over all 60 kites)."
    vmdcon -info "Usage: Faceting <symmetry_axis>  \[kite_normal\]"
    vmdcon -info ""
    vmdcon -info "Arguments:"
    vmdcon -info "<symmetry_axis>  -- Acceptable values are \"all\" or a list with any combination of"
    vmdcon -info "                    5, 3, and 2.   5 for the five-fold, 3 for the three-fold, and 2"
    vmdcon -info "                    for the two-fold symmetry axes. “all” is equivalent to \{5 3 2\}."
    vmdcon -info "\[kite_normal\] -- Optional, determines which kite normal to  use (left, right, or"
    vmdcon -info "                   average). Default is average"
    vmdcon -info ""
    vmdcon -info "Output:"
    vmdcon -info "Returns average angles and standard deviation for each symmetry axes in the order"
    vmdcon -info "they were provided. Two-fold symmetry angle with respect to the average kite-plane"
    vmdcon -info "normal return two angles, one for each two-fold axes. Two-fold symmetry angle with"
    vmdcon -info "respect to the left/right kite-plane only returns one angle, to the respective"
    vmdcon -info "left/right two-fold symmetry axis."
    vmdcon -info ""
    error ""
}

proc Faceting {args} {

    if {$::CageMatch::TRACETYPE !="kites"} {
    	vmdcon -err "Draw kites polyhedron to perform this analysis."
    	error ""
    }
    set l [llength $args]
    if { $l<1 || $l>2} {__FacetingUsage__}
    set angles [lindex $args 0]
    if {$l==2} {
	set normals [lindex $args 1]
    } else {
	set normals def_val
    }
    set difference [::struct::set difference $angles {5 3 2}] 
    if {[llength $difference]  >0 && $angles != "all" } {
	__FacetingUsage__
	
    } elseif {$angles == "all"} {	  
	set angles {5 3 2}	
    }
    switch -regexp $normals {
	(left|right) {
	    set normals [list $normals]
	}
	(average|def_val) {
	    set normals {ave}
	}
	default {
	    __FacetingUsage__
	}
    }

    set maping(5,left) 0
    set maping(5,right) 2
    set maping(5,ave) 4

    set maping(3,left) 6
    set maping(3,right) 8
    set maping(3,ave) 10

    set maping(2,left) 12
    set maping(2,right) 14
    set maping(2,ave) {16 18}
    
    set faceting [::CageMatch::Faceting]

    set results {}
    foreach ang $angles {
	foreach norm $normals {
	    set name "$ang,$norm"
	    foreach i $maping($name) {
		set results [concat $results [lrange $faceting $i [expr $i +1]]]
	    }
	}
    }
    return $results
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
    # angle type legend:
    # <angle type> = <symmetry axis>,<plane normal>
    # symmetry axis -- 5:fivefold, 3:threefold, 2l: left twofold, 2r: right twofold"
    # plane normal -- l: left, r:right, a: average
    
    set angletypes { 5,l 5,r 5,a 3,l 3,r 3,a 2l,l 2r,r 2l,a 2r,a}
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
	set vectors(2r) [vecnorm [vecsub $rtwo $CapsidCenter]]
	set vectors(2l) [vecnorm [vecsub $ltwo $CapsidCenter]]
	#sum of plane vectors
	set plane_n(a) [vecnorm [vecadd $plane_n(l) $plane_n(r)]]
	
	foreach atype $angletypes {
	    lassign [split $atype ,] point side
	    set theta($atype) [expr acos([vecdot $vectors($point) $plane_n($side)])]
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
	geodesic {set indexList [concat $PentamerIDs $HexamerIDs]
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
	threefold {set indexList $TrifoldIDs
	    set neighbours {}
	}
	(triangles|triangulated) {set indexList [concat $PentamerIDs $TwofoldIDs]
	    set neighbours [array get SymmetryNeighbours]
	}
	kleetope {set indexList [concat $PentamerIDs $HexamerIDs $GoldbergIDs]
	    set neighbours  [array get HybridNeighbours]
	}
	goldberg {set indexList $GoldbergIDs
	    set neighbours  [array get GoldbergNeighbours]
	}
	gfaces {set indexList [concat $GoldbergIDs $GoldbergPentIDs $GoldbergHexIDs]
	    set neighbours  [array get GoldbergTriNeighbours]
	}
	allvertex {
	    set indexList [concat $PentamerIDs $HexamerIDs $TwofoldIDs $TrifoldIDs $GoldbergIDs]
	    set indexList [lsort -unique $indexList]
	    set neighbours {}
	}
	default {
	    error "Unacceptable argument. Acceptable arguments are geodesic, pentamers,icosahedron, hexamers, twofold, kites, triangulated, threefold, allvertex, goldberg or kleetope"
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

proc ::CageMatch::DrawOnePick {index {molid top}} {
    variable ClusterCenters
    variable PickPointArr
    
    set drawIndex [graphics $molid pickpoint $ClusterCenters($index)]
    set PickPointArr($drawIndex) $index
#    puts "PickPointArr($drawIndex) is $PickPointArr($drawIndex)"
    return $drawIndex
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

proc ::CageMatch::PrintVertexInfo {index} {
    variable ClusterCenters 
    variable ClusterMembers
    variable TRACETYPE
    variable CLUSTERBY

    lassign  [SetupTypes $TRACETYPE 1] indexList neighbourList
    if { [lsearch $indexList $index] == -1 } {
	error "Vertex ID $index is not part of current polyhedron"
    }
    array set neighbours $neighbourList
    vmdcon -info "Vertex ID: $index"
    vmdcon -info "Coordinates: $ClusterCenters($index)"
    vmdcon -info "Chains ($CLUSTERBY): $ClusterMembers($index)"
    vmdcon -info "Current ($TRACETYPE) neighbours:$neighbours($index)"
    vmdcon -info ""

    
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

proc ::CageMatch::DrawVertices {{Ttype "geodesic"} {molid top} {rad "None"} {res "None"}} {
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

proc ::CageMatch::DrawPickPoints {{Ttype "geodesic"} {molid top}} {
    variable VERTEXRAD
    variable VERTEXRES
    set indexList [SetupTypes $Ttype 0]
    set drawList {}
    foreach i $indexList {
	lappend drawList [DrawOnePick $i $molid] 
    }
    return $drawList
}

proc ::CageMatch::DrawEdges {{Ttype "geodesic"} {molid top}} {
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
	#set coords1 $ClusterCenters($i)
	foreach j $nList {
	    set A [lsort -integer [list $i $j]]
	    if {[lsearch $drawn $A]!=-1} continue
	    #set coords2 $ClusterCenters($j)
	    lappend drawList [DrawSingleEdge $i $j $molid]
	    lappend drawn $A
	}
    }
    return [list $drawn $drawList]
}

proc ::CageMatch::DrawSingleEdge {i j {molid top}} {
    variable ClusterCenters
    variable EDGECOLOR
    variable EDGEMATERIAL
    variable EDGERAD
    variable EDGERES
    set coords1 $ClusterCenters($i)
    set coords2 $ClusterCenters($j)
    return [graphics $molid cylinder $coords1 $coords2 radius $EDGERAD resolution $EDGERES]
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

proc ::CageMatch::DrawPolygon {Ttype {molid top} {DrawType "VE"}} {
    variable LastDrawnPolygon
    variable CLEANPREVIOUS
    variable GOLDBERGCENTER
    
    if {$Ttype == "kites"} {return [DrawKites $molid $DrawType]}
    if {$CLEANPREVIOUS} {CleanLast $molid}
    foreach {drawVertex drawEdge drawFill} [SetupDrawing $DrawType] break
    
    set drawList [DrawPickPoints $Ttype $molid]
    
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
    
    set drawList [DrawPickPoints kites $molid]
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
    variable PickPointArr
    array unset PickPointArr *
    if {$ClearList == "None"} {
	set ClearList $LastDrawnPolygon
    }
    foreach id $ClearList {graphics $molid delete $id}
}

# Draws the neighbours of a given vertex for a given representation
proc ::CageMatch::DrawNeighbours {index  {Ttype "geodesic"} {molid top}} {
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

# Wrapper function for RunPolygon, used when setting trace
proc ::CageMatch::TracerFunc {name element op} {
    variable TRACETYPE
    variable TRACEDRAW
    variable TRACESELECTION
    variable TRACEMOLID
    global vmd_frame
    RunPolygon $TRACETYPE $TRACEDRAW $TRACEMOLID $vmd_frame($TRACEMOLID) $TRACESELECTION
    return
}

# Trace function for GUI vertex selection
proc ::CageMatch::PickPointTracer {name element op} {
    variable PickPointArr
    global vmd_pick_graphics

    set drawIndex [lindex $vmd_pick_graphics 1]
    set index $PickPointArr($drawIndex)
    PrintVertexInfo $index
}

# Trace function for real-time update to the drawn polyhedron 
proc ::CageMatch::EnableTrace {Ttype {drawtype "VE"} {molid top} {selection "name CA" } {icosa 1}} {
    variable TRACETYPE
    variable TRACEDRAW
    variable TRACESELECTION
    variable TRACEMOLID
    variable TRACEENABLED
    variable TRACEICOSA
    variable INITCLUSTER
    
    global vmd_frame
    global vmd_pick_graphics
    
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
    if {[lsearch [trace info variable vmd_pick_graphics] {write ::CageMatch::PickPointTracer}] == -1} {
	trace add variable vmd_pick_graphics write ::CageMatch::PickPointTracer
    }
    	
}


proc ::CageMatch::DisableTrace {} {
    variable TRACETYPE
    variable TRACEDRAW
    variable TRACESELECTION
    variable TRACEMOLID
    
    global vmd_frame
    global vmd_pick_graphics
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
    }
    
}

proc SavePolyhedron {args} {
    if {[llength $args] !=1} {
        vmdcon -info "Write current vertex definitions and polyhedron connectivity to file."
	vmdcon -info "Usage: SavePolyhedron <output>"
	vmdcon -info ""
	error ""
    }
    if {!$::CageMatch::INITCLUSTER} {
	vmdcon -err "Running DrawPolyhedron is required"
	error ""
    }
    return [eval ::CageMatch::SaveVertexinfo $args]
}

proc ::CageMatch::SaveVertexinfo {output} {
    variable ARRAYVARS
    variable NOSAVE
    set ns "::CageMatch"

    set UNSAVED [lmap x $NOSAVE {list ${ns}::${x}}]

    set arrays [lmap x $ARRAYVARS {list ${ns}::${x}}]
    
    set scalars {}
    foreach var [info vars ${ns}::*] {
	if {[lsearch $UNSAVED $var] != -1} {continue}
	if {[lsearch $arrays $var] != -1} {continue}
	if {[info exists $var]} {
	    lappend scalars $var
	} 
    }

    set fp [open $output w+]

    try {
	
	foreach var $arrays {puts $fp "array unset $var *" }
	foreach var $arrays {
	    if {[lsearch $UNSAVED $var] != -1} {continue}
	    foreach {key value} [array get $var] {
		puts $fp "set ${var}($key) [list $value]"
	    }
	}
	puts $fp "set ${ns}::INITCLUSTER 1"
	puts $fp "set ${ns}::TRACECOLOR 0"
	foreach var $scalars { puts $fp "set $var {[set $var]}"}
	puts $fp "set ${ns}::TRACECOLOR 1"

	
    } finally {
	close $fp
    }
    
    
}

proc __LoadPolyhedronUsage__ {} {
    vmdcon -info "Load Vertex information from file."
    vmdcon -info "Usage: LoadPolyhedron <polyhedron file> \[options\]"
    vmdcon -info ""
    vmdcon -info "Options are:"
    vmdcon -info "-mol <molid>     -- Cage molid. Default: top."
    vmdcon -info "-poly <polyhedron> -- Polyhedron to draw. Default: geodesic."
    
    error ""
}

proc LoadPolyhedron {args} {
    if {[llength $args] <1} {__DrawPolyhedronUsage__ 1}

    set input [lindex $args 0 0]
    set args [lreplace $args 0 0]

    set flag [lsearch $args "-mol"]
    if {$flag != -1} {
	set molid [lindex $args [expr $flag +1]]
	set args [lreplace $args $flag [expr $flag +1]]
    } else {
	set molid top
    }

    set flag [lsearch $args "-poly"]
    if {$flag != -1} {
	set poly [lindex $args [expr $flag +1]]
	set args [lreplace $args $flag [expr $flag +1]]
    } else {
	set poly geodesic
    }

    eval ::CageMatch::LoadVertexinfo $input

    if {$::CageMatch::KEEPSELECTIONS} {
    	::CageMatch::SelectCluster $molid now $::CageMatch::TRACESELECTION
    }

    ::CageMatch::UpdateVertices allvertex now $molid $::CageMatch::TRACESELECTION
    eval DrawPolyhedron $poly -mol $molid -fromfile $args
}

proc ::CageMatch::LoadVertexinfo {filename} {
    set fp [open $filename r]
    set data [read $fp ]
    close $fp
    
    set i [interp create -safe]
    try {
	$i alias set ::CageMatch::LoadSet
	$i alias array ::CageMatch::LoadArray
	$i eval $data
	
    } finally {
	interp delete $intp
    }
}


proc ::CageMatch::LoadSet {varname args} {
    if {![string match "::CageMatch::*" $varname]} {
        error "LoadSet: refusing to set '$varname' — only ::CageMatch:: variables allowed"
    }
    uplevel #0 [list set $varname {*}$args]
}

proc ::CageMatch::LoadArray {subcmd varname args} {
    if {$subcmd ne "unset"} {
        error "LoadArray: only 'array unset' is permitted in polyhedron files"
    }
    if {![string match "::CageMatch::*" $varname]} {
        error "LoadArray: refusing to modify '$varname'"
    }
    uplevel #0 [list array unset $varname {*}$args]
}


# get the shortest path tree (SPT) for unfolding the polyhedron
proc ::CageMatch::GetSPT {{rootface "None"}} {
    variable PentamerIDs
    variable SPTDistances
    variable SPTParentEdge
    variable SPTChildEdge
    variable SPTDistancesRev
    variable SPTMaxDist
    variable SPTRoot
    
    array unset SPTDistances *
    array unset SPTParentEdge *
    array unset SPTChildEdge *
    array unset SPTDistancesRev *
    
    lassign  [SetupTypes geodesic 1] indexList neighbourList
    
    array set neighbourArray $neighbourList
    if {$rootface=="None"} {
	set SPTRoot [lindex $indexList 0]
    } else {
	set SPTRoot $rootface
    }
    set queue [list $SPTRoot]
    
    set SPTDistances($SPTRoot) 0
    
    while {[llength $queue]} {
	set current [lindex $queue 0]
	set queue [lrange $queue 1 end]
	if {[lsearch [array names SPTChildEdge] $current] == -1} {set SPTChildEdge($current) {}}
	foreach neighbour $neighbourArray($current) {
	    if {[lsearch [array names SPTDistances] $neighbour] == -1} {
		set dist [expr $SPTDistances($current) + 1]
		lappend SPTDistancesRev($dist) $neighbour
		set SPTDistances($neighbour) $dist
		set SPTParentEdge($neighbour) $current
		lappend queue $neighbour
	    }
	}
    }
    
    set SPTMaxDist $dist

    while {$dist >0} {
	foreach faceid $SPTDistancesRev($dist) {
	    set parent $SPTParentEdge($faceid)
	    set SPTChildEdge($parent) [lsort -unique [concat $SPTChildEdge($parent) $faceid $SPTChildEdge($faceid)]]
    	}
	incr dist -1
    }
    set SPTDistancesRev(0) $SPTRoot
}

proc ::CageMatch::Unfold1Face_top_down {faceid} {
    variable SPTDistances
    variable SPTParentEdge
    variable SPTChildEdge
    variable SPTRoot
    variable GoldbergPentIDs
    variable GoldbergHexIDs
    variable GoldbergTriNeighbours
    variable Capsomers2Goldberg
    variable HybridNeighbours
    variable ClusterNeighbours
    variable VProjections
    variable ClusterCenters
    variable ClusterMembers
    variable ClusterSelections
    variable NetCenters
    variable CLUSTERBY
    variable TRACEMOLID

    if {$faceid == $SPTRoot} {AlignRoot2xy
	return
    }
    
    set parent $SPTParentEdge($faceid)
    set parent_vertices $HybridNeighbours($parent)
    set child_vertices $HybridNeighbours($faceid)
    lassign [::struct::set intersect $parent_vertices $child_vertices] edv1 edv2
    set posedv2 $VProjections($parent,$edv2)
    set posedv1 $VProjections($parent,$edv1)
    
    set shared_edge [vecsub  $posedv2 $posedv1]
    if {[lindex [veccross $posedv1 $posedv2] 2] <0} {
	set shared_edge [vecscale -1 $shared_edge]
    }
    set shared_center [vecscale 0.5 [vecadd $posedv2 $posedv1]]
#    set c1 $Capsomers2Goldberg($parent)
#    set c2 $Capsomers2Goldberg($faceid)

    set sel [atomselect $TRACEMOLID "$CLUSTERBY $ClusterMembers($faceid)"]
    lassign [measure inertia $sel] COM Ivec
    lassign [CompareIvec $Ivec {0.0 0.0 1.0}] normal1 angle
    

    
    set t_matrix [trans center $shared_center  axis $shared_edge $angle rad]

    
    set segments $ClusterMembers($faceid)
    set all_children $SPTChildEdge($faceid)
	     
        
    foreach id $all_children {
    	set segments [concat $segments $ClusterMembers($id)]
    	foreach {name value} [array get VProjections "$id,*"] {
    	    set VProjections($name) [coordtrans $t_matrix $value] 
    	}
    }

    foreach {name value} [array get VProjections "$faceid,*"] {
    	set VProjections($name) [coordtrans $t_matrix $value]
    	set VProjections($name) [concat [lrange $VProjections($name) 0 1] 0.0]
    }

    $sel delete
    set sel [atomselect top "$CLUSTERBY $segments"]
    
    $sel move $t_matrix
    $sel delete
    return $t_matrix
}


proc ::CageMatch::AlignRoot2xy {} {
    variable SPTRoot
    variable SPTDistances
    variable SPTParentEdge
    variable SPTChildEdge
    variable ClusterCenters
    variable ClusterMembers
    variable HybridNeighbours
    variable Capsomers2Goldberg
    variable CLUSTERBY
    variable TRACEMOLID
    variable TRACESELECTION
    variable VProjections

    set sel1 [atomselect $TRACEMOLID "$CLUSTERBY $ClusterMembers($SPTRoot)"]
    lassign [measure inertia $sel1] COM Ivec
    $sel1 delete
    
    set selection [lmap x $SPTChildEdge($SPTRoot) {list $ClusterMembers($x)}]
    set selection [join [join $selection]]
    set selection [concat $ClusterMembers($SPTRoot) $selection]
    set sel [atomselect $TRACEMOLID "$CLUSTERBY $selection"]
   
    

    lassign [CompareIvec $Ivec $COM] vec1 angle
    set vec2 {0.0 0.0 1.0}
    set rotvec [veccross $vec1 $vec2]
    set sine   [veclength $rotvec]
    set cosine [vecdot $vec1 $vec2]
    set angle [expr atan2($sine,$cosine)]

    set t_matrix [trans origin $COM  axis $rotvec $angle rad]
    $sel move $t_matrix
    $sel delete
    UpdateVertices goldberg  now $TRACEMOLID $TRACESELECTION

    set indexList [SetupTypes geodesic 0]
    ResetVProjections

}

proc ::CageMatch::ResetVProjections {} {
    variable VProjections
    variable SPTRoot
    variable SPTParentEdge
    variable HybridNeighbours
    variable ClusterCenters

    foreach {child parent} [array get SPTParentEdge] {
	set nlist [::struct::set difference $HybridNeighbours($child) $HybridNeighbours($parent)]
	foreach i $nlist { set VProjections($child,$i) $ClusterCenters($i)}
    }
    foreach i $HybridNeighbours($SPTRoot) {
	set VProjections($SPTRoot,$i) [concat [lrange $ClusterCenters($i) 0 1] 0.0]
    }
}

proc ::CageMatch::MakePolyNet {} {
    variable SPTDistancesRev
    variable TRACEMOLID
    variable SPTMaxDist
    set startframe [molinfo $TRACEMOLID get frame]
    for {set i 0} {$i<=$SPTMaxDist} {incr i} {
	foreach faceid $SPTDistancesRev($i) {
	    animate dup $TRACEMOLID
	    Unfold1Face_top_down $faceid
	    display update
	}
    }
    set endframe [molinfo $TRACEMOLID get frame]
    return [list $startframe $endframe]
}


proc __PolyNetUsage__ {} {
    vmdcon -info "Generate 2D Goldberg polyhedron net projection."
    vmdcon -info "Usage: PolyhedronNet <source_face> \[options\]"
    vmdcon -info ""
    vmdcon -info "Arguments:"
    vmdcon -info "  <source_face>  -- Geodesic polyhedron vertex ID. Designates the capsomer from"
    vmdcon -info "                    which to start the Goldberg polyhedron net. Value of 0 makes"
    vmdcon -info "                    PolyhedronNet select the first PentamerID as a starting point."
    vmdcon -info ""
    vmdcon -info "Options (options default to polyhedron settings):"
    vmdcon -info "-color <ColorID> -- Edge color."
    vmdcon -info "-rad <radius>    -- Edge radius."
    vmdcon -info "-progress        -- Keep frames generated in every step of the polyhedron"
    vmdcon -info "                    net construction. By default, only the result is kept."   
    vmdcon -info ""
    error ""
}
proc PolyhedronNet {args} {

    set oldcolor $::CageMatch::EDGECOLOR
    set oldrad $::CageMatch::EDGERAD
    set ids [concat $::CageMatch::PentamerIDs $::CageMatch::HexamerIDs]

    if {[llength $args]< 1 } {__PolyNetUsage__}
    set faceid [lindex $args 0]
    set args [lrange $args 1 end]
    
    set flag [lsearch $args "-help"]
    if {$flag != -1 } { __PolyNetUsage__}

    set flag [lsearch $args "-color"]
    if {$flag !=-1} {
	set ::CageMatch::EDGECOLOR [lindex $args [expr $flag + 1]]
	set args [lreplace $args $flag [expr $flag + 1]]
    }
    
    set flag [lsearch $args "-rad"]
    if {$flag !=-1} {
	set ::CageMatch::EDGERAD [lindex $args [expr $flag + 1] ]
	set args [lreplace $args $flag [expr $flag + 1]]
    }

    set flag [lsearch $args "-progress"]
    if {$flag !=-1} {
	set keep 1
	set args [lreplace $args $flag  $flag]
    } else {
	set keep 0
    }
    
    try {
	if {[lsearch $ids $faceid] == -1 && $faceid !=0 } {
	    __PolyNetUsage__
	}	
	if {[llength $args]} {__PolyNetUsage__}
	uplevel {StopPolyhedron 1}
	if {$faceid} {
	    ::CageMatch::GetSPT $faceid
	} else {
	    ::CageMatch::GetSPT
	}
	lassign [::CageMatch::MakePolyNet] start end
	::CageMatch::DrawNet
	if {!$keep} {
	    animate delete beg [expr $start +1] end [expr $end -1] $::CageMatch::TRACEMOLID   
	}
    } finally {
	set ::CageMatch::EDGECOLOR $oldcolor
	set ::CageMatch::EDGERAD $oldrad
    }
    return
}

proc ::CageMatch::DrawNet {} {
    variable SPTDistancesRev
    variable TRACEMOLID
    variable SPTMaxDist
    variable HybridNeighbours 
    variable LastDrawnPolygon
    variable CLEANPREVIOUS
    variable GOLDBERGCENTER
    variable TRACEMOLID
    if {$CLEANPREVIOUS} {CleanLast $TRACEMOLID}

    set drawnList {}
    for { set i $SPTMaxDist} {$i > 0} {incr i -1} {
	foreach faceid $SPTDistancesRev($i) {
	    set drawnList [concat $drawnList [DrawNetFace $faceid]] 
	}
    }
    set LastDrawnPolygon $drawnList
}

proc ::CageMatch::DrawNetFace {faceid} {
    variable SPTParentEdge
    variable HybridNeighbours
    variable GoldbergNeighbours
    variable EDGECOLOR
    variable EDGERAD
    variable EDGEMATERIAL
    variable TRACEMOLID
    variable EDGERES
    variable VProjections
    
    set parent_vertices {}

    foreach {child parent} [array get SPTParentEdge $faceid] {        
	
	set parent_vertices $HybridNeighbours($parent)
    }
    
    set child_vertices $HybridNeighbours($faceid)
    set difference [::struct::set difference $child_vertices $parent_vertices]
    set intersect [::struct::set intersect $child_vertices $parent_vertices]

    foreach id $difference {set Coords($id) $VProjections($faceid,$id)}
    foreach id $intersect {set Coords($id) $VProjections($parent,$id)}
    set drawList [graphics $TRACEMOLID material $EDGEMATERIAL]
    lappend drawList [graphics $TRACEMOLID color $EDGECOLOR]

    set drawn {}
    
    foreach i $child_vertices {
	set coords1 $Coords($i)
	lappend drawList [graphics $TRACEMOLID sphere $coords1 radius $EDGERAD resolution $EDGERES]
    	set nList [::struct::set intersect $GoldbergNeighbours($i) $child_vertices]
	foreach j $nList {
	    set A [lsort -integer [list $i $j]]
	    if {[lsearch $drawn $A]!=-1} continue
	    set coords2 $Coords($j)
	    lappend drawList [graphics $TRACEMOLID cylinder $coords1 $coords2 radius $EDGERAD resolution $EDGERES]
	    lappend drawn $A
	}
    }
    return $drawList
}

proc ColorByPath {} {

    set root $::CageMatch::SPTRoot
    set cid 1
    ViewClusterMembers $root -color "ColorID 0"
    set capsomerIDs [concat $::CageMatch::PentamerIDs $::CageMatch::HexamerIDs]
    foreach {name value} [array get ::CageMatch::SPTDistances] {
	lappend dists [list $name $value]
    }
    
    set dists {}
    foreach {name value} [array get ::CageMatch::SPTDistances] {
	lappend dists [list $name $value]
    }

    set sorted_dists [lsort -index 1 -integer -decreasing $dists ]
    
    set checked_paths {} 
    foreach val  $sorted_dists {
	lassign $val faceid distances
	if {[lsearch $checked_paths $faceid] != -1} {continue}
	set path [::CageMatch::GetUpPath $faceid]
	set unique_elements [::struct::set difference $path $checked_paths]
	set checked_paths [::struct::set union $checked_paths $path]
	#	set Actual_paths($val) $path
	if {$cid>33} {set cid 1}
	ViewClusterMembers $unique_elements -color "ColorID $cid"
	incr cid
    }
}

proc ColorByDistance {} {

    set root $::CageMatch::SPTRoot
    set cid 1
    ViewClusterMembers $root -color "ColorID 0"
    array set ColorDist {}
    foreach {name value} [array get ::CageMatch::SPTDistances] {
	lappend ColorDist($value)  $name
    }

    foreach d [lsort -integer [array names ColorDist]] {
	if {$cid>33} {set cid 1}
	ViewClusterMembers $ColorDist($d) -color "ColorID $cid"
	incr cid
    }
    
}

proc ::CageMatch::GetUpPath {faceid} {
    variable SPTParentEdge
    variable SPTDistances
    variable SPTRoot

    if {$faceid==$SPTRoot} {return}
    set parent $SPTParentEdge($faceid)
    set pathList [list $faceid]
    while {$parent!=$SPTRoot} {
	lappend pathList $parent
	set parent $SPTParentEdge($parent)
    }
    return $pathList
}
