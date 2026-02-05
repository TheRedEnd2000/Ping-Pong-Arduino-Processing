# Ping-Pong Arduino + Processing

Ein klassisches Ping-Pong-Spiel in **Processing**, das entweder über die Tastatur oder über **Arduino / Serial Controller** gesteuert werden kann. Inklusive Soundeffekten, Hintergrundmusik und Startscreen mit Vorschau-Ball.
Entwickelt von Fabian. (Credit: Adrian)

---

## Features

- Spieler 1 & Spieler 2 Steuerung über:
  - **Tastatur**: W/S und Pfeiltasten
  - **Arduino / Serial**: Potis
- Punkte-System mit einstellbarer Gewinnpunktzahl
- **Bot Mode (Singleplayer)**
  - Mehrere Schwierigkeitsstufen (Baby → Impossible)
- Soundeffekte:
  - Treffer, Punkt, Start, Sieg
- Hintergrundmusik im Spiel und im Menü
- Lautstärkeregler im Startscreen
- Auto-Reset nach Spielende

---

## Bot Mode

Das Spiel kann optional **gegen einen Bot (KI)** gespielt werden.  
Der Bot steuert **Spieler 2** und reagiert abhängig vom gewählten Schwierigkeitsgrad.

### Schwierigkeitsstufen

| Stufe | Schnellichkeit |
|-----|-------------|
| **Baby** | 3 |
| **Easy** | 5 |
| **Normal** | 6 |
| **Hard** | 8 |
| **Very Hard** | 14 |
| **Impossible** | 20 |

### Steuerung (Bot)

- `[B]` → Bot Mode ein / aus
- `[←] / [→]` → Schwierigkeit ändern *(nur bei aktivem Bot)*

---

## Anforderungen

- **Processing 4.x** (https://processing.org/)
- **Arduino IDE** (optional für Serial-Steuerung [Benötigt Speziellen Build für STM32]) 
- Processing Libraries:
  - [Sound](https://processing.org/reference/libraries/sound/) (`Sketch -> Import Library -> Add Library -> Sound`)
  - [Serial](https://processing.org/reference/libraries/serial/)

---

## Installation

1. **Repository klonen:**
```
git clone https://github.com/dein-benutzername/ping-pong-arduino-processing.git
```

2. **Processing öffnen und Datei laden:**

- Datei `processing_ping_pong.pde` öffnen

3. **Sicherstellen, dass alle Sounddateien im `data`-Ordner liegen:**
```
data/
hit.mp3
score.mp3
start.mp3
win.mp3
menu.mp3
ambient.mp3
```

4. **Arduino (optional):**

- Arduino an den PC anschließen
- COM-Port im Startscreen oder in `setup()` einstellen
- Daten im Format `Paddle1,Paddle2\n` senden (0–100%)

**Wichtig: Anschluss Spieler 1 Pin A4, Anschluss Spieler 2 Pin A3**
Kann auch in der `arduino_ping_pong.ino` Datei geändert werden.

---

## Steuerung

### Tastatur-Modus
- Spieler 1: **W / S**
- Spieler 2: **↑ / ↓**
- Startscreen:
- `[ENTER]` Start
- `[R]` Wechsel zwischen Keys/Serial
- `[+]` / `[-]` Punkte zum Sieg ändern
- `[V]` Lautstärke erhöhen
- `[C]` Lautstärke verringern

### Serial-Modus
- COM-Port eingeben (z.B. `COM3`)
- Arduino sendet Paddle-Positionen: `p1Percent,p2Percent\n`
- Prozentwert 0–100 entspricht Paddle-Position von oben nach unten

---

## Wichtig

- Verwende **Processing Vollbildmodus**, um die richtige Skalierung zu haben
- Stelle sicher, dass die Serial-Library korrekt installiert ist
- Sound-Dateien müssen im `data`-Ordner liegen, sonst werden Fehler angezeigt
- Für Arduino-Integration: passende Baudrate (`115200`) verwenden
