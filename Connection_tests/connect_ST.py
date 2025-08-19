import serial
import time

class SerialConnection:
    def __init__(self, port='COM3', baudrate=9600, bytesize=8, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE):
        self.port = port
        self.baudrate = baudrate
        self.bytesize = bytesize
        self.parity = parity
        self.stopbits = stopbits
        self.serial = None

    def open(self):
        try:
            self.serial = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                bytesize=self.bytesize,
                parity=self.parity,
                stopbits=self.stopbits,
                timeout=1  # Set a timeout for read operations
            )
            print(f"Connected to {self.port} at {self.baudrate} bps")
            return True
        except serial.SerialException as e:
            print(f"Error opening serial port: {e}")
            return False

    def close(self):
        if self.serial and self.serial.is_open:
            self.serial.close()
            print("Connection closed.")

    def send_data(self, data):
        if self.serial and self.serial.is_open:
            if isinstance(data, str):
                data = data.encode()  # Convert string to bytes
            self.serial.write(data)
            print(f"Sent: {data}")
            return True
        return False

    def receive_data(self, size=1024):
        if self.serial and self.serial.is_open:
            data = self.serial.read(size)
            print(f"Received: {data}")
            return data
        return None

    def set_timeout(self, timeout):
        if self.serial:
            self.serial.timeout = timeout
            print(f"Timeout set to {timeout} seconds.")

if __name__ == "__main__":
    # Example usage
    connection = SerialConnection(port='COM3', baudrate=9600)  # Updated to COM3 and 9600 bps

    if connection.open():
        connection.send_data("Hello ST-Link")
        time.sleep(1)  # Wait for a moment to receive data
        response = connection.receive_data()
        connection.close()
