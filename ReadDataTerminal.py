#!/usr/bin/env python3
"""
Terminal‑only serial monitor (Windows‑compatible).
- Reads lines from the serial port in a background thread.
- Prints each line with a timestamp.
- Clean shutdown on Ctrl‑C (SIGINT) or SIGTERM.
"""

import sys
import signal
import threading
import datetime
import time

import serial  # pip install pyserial


# ----------------------------------------------------------------------
# Configuration (adjust as needed)
# ----------------------------------------------------------------------
PORT = "/dev/ttyACM0"  # e.g., "/dev/ttyUSB0" (Linux) or "COM6" (Windows)
BAUDRATE = 115200
TIMEOUT = 1.0          # seconds


# ----------------------------------------------------------------------
# Serial‑reading thread
# ----------------------------------------------------------------------
class SerialReader(threading.Thread):
    """Continuously read lines from ``ser`` and forward them to a callback."""
    def __init__(self, ser, line_callback):
        super().__init__(daemon=True)          # daemon → exits with the program
        self.ser = ser
        self.line_callback = line_callback
        self._running = threading.Event()
        self._running.set()

    def run(self):
        while self._running.is_set():
            try:
                if self.ser.in_waiting:
                    raw = self.ser.readline()
                    line = raw.decode("utf-8", errors="replace").rstrip()
                    self.line_callback(line)
                else:
                    # No data – short sleep to avoid busy‑looping
                    time.sleep(0.01)
            except serial.SerialException as exc:
                print(f"\n[error] Serial exception: {exc}", file=sys.stderr)
                break

    def stop(self):
        self._running.clear()


# ----------------------------------------------------------------------
# Helper to print a line with a timestamp
# ----------------------------------------------------------------------
def print_line(line: str):
    ts = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
    print(f"{ts} | {line}")


# ----------------------------------------------------------------------
# Graceful shutdown handling
# ----------------------------------------------------------------------
def install_signal_handlers(reader: SerialReader, ser: serial.Serial):
    def _handler(signum, frame):
        print("\n[info] Shutting down…", file=sys.stderr)
        reader.stop()
        reader.join(timeout=2.0)
        ser.close()
        sys.exit(0)

    for sig in (signal.SIGINT, signal.SIGTERM):
        signal.signal(sig, _handler)


# ----------------------------------------------------------------------
# Main entry point
# ----------------------------------------------------------------------
def main():
    try:
        ser = serial.Serial(PORT, BAUDRATE, timeout=TIMEOUT)
    except serial.SerialException as exc:
        print(f"[error] Could not open serial port {PORT!r}: {exc}", file=sys.stderr)
        sys.exit(1)

    print(f"[info] Connected to {PORT} @ {BAUDRATE} baud (timeout={TIMEOUT}s)")
    print("[info] Press Ctrl‑C to exit.\n")

    reader = SerialReader(ser, print_line)
    install_signal_handlers(reader, ser)

    reader.start()

    # Keep the main thread alive.  On Windows the `signal.pause()` and
    # `signal.sigwait()` functions are unavailable, so we simply sleep
    # in a loop.  The signal handler will interrupt this sleep when
    # Ctrl‑C (SIGINT) is pressed.
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        # Fallback if the signal handler didn't fire (e.g., when run from
        # an IDE that swallows signals).
        pass


if __name__ == "__main__":
    main()
