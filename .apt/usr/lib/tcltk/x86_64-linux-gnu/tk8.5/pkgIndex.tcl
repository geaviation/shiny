if {[catch {package present Tcl 8.5.0}]} return
package ifneeded Tk 8.5.15 [list load [file normalize [file join /usr/lib/x86_64-linux-gnu libtk8.5.so]] Tk]
