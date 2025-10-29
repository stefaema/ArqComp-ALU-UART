import serial
import threading
import time
from enum import IntEnum
import tkinter as tk
from tkinter import ttk, messagebox

# =============================================================================
# CONFIGURACIÓN
# =============================================================================
SERIAL_PORT = 'COM12'
BAUD_RATE = 9600
BYTE_DELAY = 0.002  # segundos entre bytes (~2 ms, similar al testbench)


# =============================================================================
# ENUM DE OPERACIONES
# =============================================================================
class OpCode(IntEnum):
    ADD = 0b100000
    SUB = 0b100010
    AND = 0b100100
    OR  = 0b100101
    XOR = 0b100110
    SRA = 0b000011
    SRL = 0b000010
    NOR = 0b100111


# =============================================================================
# FUNCIONES DE PROTOCOLO
# =============================================================================
def build_operation_packet(op1, op2, opcode):
    op_byte = opcode.value & 0xFF
    # Devuelve una lista para enviar bytewise
    return [0xCD, op1 & 0xFF, op2 & 0xFF, op_byte]


def build_display_packet():
    # También en lista (para consistencia)
    return [0xD1]


def parse_fpga_response(raw_data: bytes):
    if len(raw_data) < 2:
        return None
    result_byte, flags_byte = raw_data[0], raw_data[1]
    result_signed = result_byte if result_byte < 128 else result_byte - 256
    zero_flag = bool(flags_byte & 0b00000001)
    overflow_flag = bool(flags_byte & 0b00000010)
    return result_signed, zero_flag, overflow_flag


def send_bytewise(ser, byte_seq, delay_s=BYTE_DELAY):
    """
    Envía bytes uno por uno, con flush y un pequeño retardo entre cada uno.
    """
    for b in byte_seq:
        ser.write(bytes([b]))
        ser.flush()
        print(f"[TX BYTE] -> {b:02X}")
        time.sleep(delay_s)


# =============================================================================
# HILO DE RECEPCIÓN
# =============================================================================
def uart_reader(ser, raw_text, formatted_text):
    """
    Hilo de recepción UART.
    Muestra los datos tanto en la GUI como en la consola (stdout).
    """
    buffer = bytearray()
    while True:
        try:
            if ser.in_waiting > 0:
                data = ser.read(ser.in_waiting)
                if not data:
                    continue

                # === Consola (modo debug) ===
                timestamp = time.strftime("%H:%M:%S")
                print(f"[{timestamp}] [RX RAW]: {data.hex(' ').upper()}")

                # === GUI RAW ===
                hex_data = data.hex(' ').upper()
                raw_text.insert(tk.END, f"[RX] {hex_data}\n")
                raw_text.see(tk.END)

                # === Acumular y parsear ===
                buffer.extend(data)
                if len(buffer) >= 2:
                    parsed = parse_fpga_response(buffer[:2])
                    if parsed:
                        result, zero, ovf = parsed

                        # Consola
                        print(f"[{timestamp}] [RX PARSED]: Resultado={result}, Zero={int(zero)}, Overflow={int(ovf)}")

                        # GUI
                        formatted_text.insert(
                            tk.END,
                            f"Resultado = {result} | Zero = {int(zero)} | Overflow = {int(ovf)}\n"
                        )
                        formatted_text.see(tk.END)

                        # Limpiar buffer
                        buffer.clear()

            time.sleep(0.2)

        except Exception as e:
            raw_text.insert(tk.END, f"[ERROR RX] {e}\n")
            print(f"[RX ERROR] {e}")
            break


# =============================================================================
# GUI
# =============================================================================
class UARTGui:
    def __init__(self, master):
        self.master = master
        master.title("Panel de Control UART - ALU")
        master.geometry("640x480")
        master.resizable(False, False)

        # Intento de conexión serial
        try:
            self.ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
            print(f"[INFO] Conectado a {SERIAL_PORT} @ {BAUD_RATE} bps")
        except Exception as e:
            messagebox.showerror("Error de conexión", str(e))
            self.ser = None

        # === Panel Calcular ===
        calc_frame = ttk.LabelFrame(master, text="Calcular", padding=10)
        calc_frame.pack(fill="x", padx=10, pady=5)

        self.entry_a = ttk.Entry(calc_frame, width=10)
        self.entry_b = ttk.Entry(calc_frame, width=10)
        self.combo_op = ttk.Combobox(calc_frame, values=[op.name for op in OpCode], width=10, state="readonly")
        self.combo_op.current(0)
        self.btn_send = ttk.Button(calc_frame, text="Enviar operación", command=self.send_operation)

        self.entry_a.grid(row=0, column=0, padx=5, pady=5)
        self.combo_op.grid(row=0, column=1, padx=5, pady=5)
        self.entry_b.grid(row=0, column=2, padx=5, pady=5)
        self.btn_send.grid(row=0, column=3, padx=10, pady=5)

        # === Panel Mostrar ===
        disp_frame = ttk.LabelFrame(master, text="Mostrar", padding=10)
        disp_frame.pack(fill="x", padx=10, pady=5)

        self.btn_display = ttk.Button(disp_frame, text="Solicitar resultado", command=self.send_display, state="disabled")
        self.btn_display.pack(side="left", padx=5, pady=5)

        # === Panel RX ===
        rx_frame = ttk.LabelFrame(master, text="Recepción UART", padding=10)
        rx_frame.pack(fill="both", expand=True, padx=10, pady=5)

        ttk.Label(rx_frame, text="RAW").pack(anchor="w")
        self.text_raw = tk.Text(rx_frame, height=5, bg="#111", fg="#0f0")
        self.text_raw.pack(fill="x", padx=5, pady=5)

        ttk.Label(rx_frame, text="FORMATTED").pack(anchor="w")
        self.text_fmt = tk.Text(rx_frame, height=5, bg="#111", fg="#0af")
        self.text_fmt.pack(fill="x", padx=5, pady=5)

        # === Hilo RX ===
        if self.ser:
            threading.Thread(target=uart_reader, args=(self.ser, self.text_raw, self.text_fmt), daemon=True).start()

    # === Funciones ===
    def send_operation(self):
        if not self.ser:
            messagebox.showerror("Error", "Puerto serial no abierto.")
            return
        try:
            op1 = int(self.entry_a.get())
            op2 = int(self.entry_b.get())
            if not (-128 <= op1 <= 127) or not (-128 <= op2 <= 127):
                raise ValueError("Los operandos deben ser de 8 bits.")
            opcode = OpCode[self.combo_op.get()]
            if opcode is None:
                raise ValueError("Operación inválida seleccionada.")
            packet = build_operation_packet(op1, op2, opcode)

            # Envío byte a byte
            send_bytewise(self.ser, packet, delay_s=BYTE_DELAY)

            # GUI feedback
            self.text_raw.insert(tk.END, f"[TX] {' '.join(f'{b:02X}' for b in packet)}\n")
            self.text_raw.see(tk.END)
            self.btn_display["state"] = "normal"

        except Exception as e:
            messagebox.showerror("Error al enviar", str(e))

    def send_display(self):
        if not self.ser:
            return
        pkt = build_display_packet()
        send_bytewise(self.ser, pkt, delay_s=BYTE_DELAY)
        self.text_raw.insert(tk.END, f"[TX] {' '.join(f'{b:02X}' for b in pkt)} (CMD_DISPLAY)\n")
        self.text_raw.see(tk.END)


# =============================================================================
# MAIN
# =============================================================================
if __name__ == "__main__":
    root = tk.Tk()
    app = UARTGui(root)
    root.mainloop()
