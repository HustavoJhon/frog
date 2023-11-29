from time import sleep
from rich.console import Console
from rich.align import Align
from rich.text import Text
from rich.panel import Panel

console = Console()

with open("mensajes.txt", "r") as file:
    mensajes = file.read().strip().split(',')

for mensaje in mensajes:
    with console.screen(style="bold white on red") as screen:
        text = Align.center(
            Text.from_markup(f"[blink]{mensaje}[/blink]"),
            vertical="middle",
        )
        screen.update(Panel(text))
        sleep(2)
