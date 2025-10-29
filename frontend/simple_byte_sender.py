# simple_byte_sender.py
import serial
import time
import argparse

# =============================================================================
# CONFIGURACION
# =============================================================================
# Asegurate de que el puerto COM sea el correcto para tu sistema.
# Puedes encontrarlo en el Administrador de Dispositivos de Windows.
SERIAL_PORT = 'COM12' 
BAUD_RATE = 9600

# =============================================================================
# FUNCION PRINCIPAL
# =============================================================================
def send_single_byte(byte_to_send):
    """
    Abre el puerto serie, envia un unico byte y cierra el puerto.
    """
    ser = None # Inicializar a None para el bloque finally
    try:
        # Abrir puerto serie
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        print(f"Puerto {SERIAL_PORT} abierto a {BAUD_RATE} bps.")
        
        # El metodo write espera un objeto tipo bytes.
        # Creamos uno a partir de una lista que contiene nuestro byte.
        data_to_send = bytes([byte_to_send])
        
        # Enviar el byte
        ser.write(data_to_send)
        
        # Usamos f-string con formato hexadecimal (02X) para una mejor visualizacion
        print(f"Byte enviado: 0x{byte_to_send:02X} ({byte_to_send})")

    except serial.SerialException as e:
        print(f"Error: No se pudo abrir o escribir en el puerto {SERIAL_PORT}.")
        print(f"Detalle: {e}")
        
    finally:
        # Asegurarse de que el puerto se cierre siempre, incluso si hay un error
        if ser and ser.is_open:
            ser.close()
            print(f"Puerto {SERIAL_PORT} cerrado.")

# =============================================================================
# PUNTO DE ENTRADA DEL SCRIPT
# =============================================================================
if __name__ == "__main__":
    # Se utiliza argparse para poder pasar el byte desde la linea de comandos
    parser = argparse.ArgumentParser(description="Envia un unico byte a un puerto serie.")
    
    # El argumento 'byte' sera leido como string, por eso se convierte a int.
    # El 'int(x, 0)' permite interpretar tanto decimal ('240') como hexadecimal ('0xF0').
    parser.add_argument(
        'byte', 
        type=lambda x: int(x, 0), 
        default='0xF0', 
        nargs='?', # El argumento es opcional
        help="El byte a enviar (ej: 240 o 0xF0). Por defecto es 0xF0."
    )
    
    args = parser.parse_args()
    
    # Llamar a la funcion principal con el byte parseado
    send_single_byte(args.byte)
