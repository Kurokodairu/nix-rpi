#!/usr/bin/env python3
from gpiozero import CPUTemperature
from datetime import datetime

cpu = CPUTemperature()
print(f"[{datetime.now():%Y-%m-%d %H:%M:%S}] CPU: {cpu.temperature:.1f}°C")