# ============================================================================
# Script Tcl para crear el proyecto de Vivado para el TP2
# ============================================================================
# Se asume que este script se ejecuta desde la raiz del proyecto.

# --- 1. Definicion de Variables del Proyecto ---
set project_name "tp2_project"
set project_dir "./vivado_project" ;# Directorio donde Vivado creara los archivos del proyecto
set part_name "xc7a35tcpg236-1"   ;# Part number para la Basys3

# --- 2. Creacion del Proyecto ---
# Borra el directorio del proyecto si ya existe para una creacion limpia
if { [file isdirectory $project_dir] } {
    puts "INFO: Borrando proyecto existente en $project_dir"
    file delete -force $project_dir
}
puts "INFO: Creando proyecto '$project_name' en '$project_dir'"
create_project $project_name $project_dir -part $part_name

# --- 3. Anadir Fuentes de Diseno (HDL) ---
# Usamos 'glob' para encontrar todos los archivos .v en el directorio de fuentes
# Esto es automatico: si anades un nuevo archivo .v, sera incluido la proxima vez que corras el script.
set design_sources [glob ./backend/sources/*.v]
puts "INFO: Anadiendo fuentes de diseno: $design_sources"
add_files -norecurse $design_sources

# --- 4. Anadir Fuentes de Simulacion ---
# Anadimos el testbench al fileset de simulacion 'sim_1'
set sim_sources [glob ./backend/simulations/*.v]
puts "INFO: Anadiendo fuentes de simulacion: $sim_sources"
add_files -fileset sim_1 -norecurse $sim_sources

# --- 5. Anadir Archivo de Constraints ---
set constr_file [glob ./backend/constraints/*.xdc]
puts "INFO: Anadiendo archivo de constraints: $constr_file"
add_files -fileset constrs_1 -norecurse $constr_file

# --- 6. Configurar Propiedades del Proyecto ---
# Especificar cual es el modulo 'top' de la jerarquia
set_property top tp2_top [current_fileset]

# Actualizar el orden de compilacion por si acaso
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: La creacion del proyecto ha finalizado."
puts "INFO: Puedes abrir el proyecto con Vivado en la siguiente ruta:"
puts "$project_dir/$project_name.xpr"
