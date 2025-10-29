# ============================================================================
# Script Tcl para ANADIR FUENTES a un proyecto de Vivado YA CREADO
#
# INSTRUCCIONES:
# 1. Crea tu proyecto de Vivado manualmente (sin anadir fuentes).
# 2. Abre la consola Tcl en Vivado (en la parte inferior de la GUI).
# 3. Ejecuta este script escribiendo: source ./add_sources.tcl
#    (Asegurate de que la ruta sea correcta desde donde Vivado se ejecuto).
# ============================================================================

# Cambia el directorio de trabajo actual al directorio donde se encuentra este script.
# Esto es CRUCIAL para que las rutas relativas (./backend/...) funcionen correctamente.
cd [file dirname [info script]]
puts "INFO: Directorio de trabajo cambiado a [pwd]"

# --- 1. Anadir Fuentes de Diseno (HDL) ---
# Busca todos los archivos .v en la carpeta de fuentes.
set design_sources [glob -nocomplain ./backend/sources/*.v]

if { [llength $design_sources] > 0 } {
    puts "INFO: Anadiendo fuentes de diseno: $design_sources"
    # Anade los archivos encontrados al fileset de diseno (sources_1)
    add_files -norecurse $design_sources
} else {
    puts "WARNING: No se encontraron archivos de diseno (.v) en ./backend/sources/"
}


# --- 2. Anadir Archivo de Constraints ---
# Busca el archivo .xdc en la carpeta de constraints.
set constr_file [glob -nocomplain ./backend/constraints/*.xdc]

if { [llength $constr_file] > 0 } {
    puts "INFO: Anadiendo archivo de constraints: $constr_file"
    # Anade el archivo encontrado al fileset de constraints (constrs_1)
    add_files -fileset constrs_1 -norecurse $constr_file
} else {
    puts "WARNING: No se encontro un archivo de constraints (.xdc) en ./backend/constraints/"
}


# --- 3. Configurar Propiedades y Actualizar ---
# Es una buena practica re-establecer el top module y actualizar el orden
# de compilacion despues de anadir archivos.
puts "INFO: Estableciendo 'tp2_top' como modulo superior."
set_property top tp2_top [current_fileset]

puts "INFO: Actualizando el orden de compilacion."
update_compile_order -fileset sources_1

puts "\nINFO: Script finalizado. Las fuentes y constraints han sido anadidos al proyecto actual."
