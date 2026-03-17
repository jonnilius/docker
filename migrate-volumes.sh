#!/bin/bash

# Farben
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Keine Farbe

# Basisverzeichnis für Docker-Stacks
BASE_DIR="$HOME/docker"

# Header
echo -e "${RED}==============================${NC}"
echo -e "   Docker Volume Mover"
echo -e "${RED}==============================${NC}"
echo

mapfile -t VOLUMES < <(docker volume ls --format "{{.Name}}")
if [ ${#VOLUMES[@]} -eq 0 ]; then
        echo "Keine Volumes gefunden."
        exit 0
fi

echo -e "${CYAN}Ziel-Volume auswählen:${NC}"
echo " 0) [Volume erstellen]"
for i in "${!VOLUMES[@]}"; do

    # Volumename abrufen
    VOLUME="${VOLUMES[$i]}"
    printf " %d) %s " $((i+1)) "${VOLUME}"
    echo

done

# Benutzereingabe für Ziel-Volume
echo
echo -ne "${CYAN}Ziel-Volume auswählen (Nummer): ${NC}"
read -r SELECTION

## Validierung
# Überprüfen, ob Eingabe eine Zahl ist
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
        echo "Ungültige Eingabe. Bitte eine Zahl eingeben."
        exit 1
fi
# Überprüfen, ob Zahl im gültigen Bereich ist
if [ "$SELECTION" -gt "${#VOLUMES[@]}" ]; then
        echo "Nummer existiert nicht."
        exit 1
fi

# Auswahl auflösen
if [ "$SELECTION" -eq 0 ]; then
    echo -ne "${CYAN}Geben Sie den Namen des neuen Volumes ein: ${NC}"
    read -r NEW_VOLUME
    docker volume create "$NEW_VOLUME"
    TARGET_VOLUME="$NEW_VOLUME"
else
    TARGET_VOLUME="${VOLUMES[$((SELECTION-1))]}"
fi

# Container vom Ziel-Volume stoppen
TARGET_CONTAINERS=$(docker ps -q --filter "volume=${TARGET_VOLUME}")
if [ -n "$TARGET_CONTAINERS" ]; then
    echo -e "${YELLOW}Stoppe Container, die das Ziel-Volume verwenden...${NC}"
    docker stop $TARGET_CONTAINERS
fi

echo -ne "${CYAN}Geben Sie die Nummer des Quell-Volumes ein: ${NC}"
read -r SOURCE_SELECTION
## Validierung
# Überprüfen, ob Eingabe eine Zahl ist
if ! [[ "$SOURCE_SELECTION" =~ ^[0-9]+$ ]]; then
        echo "Ungültige Eingabe. Bitte eine Zahl eingeben."
        exit 1
fi
# Überprüfen, ob Zahl im gültigen Bereich ist (mind. 1, da 0 kein Quell-Volume ist)
if [ "$SOURCE_SELECTION" -lt 1 ] || [ "$SOURCE_SELECTION" -gt "${#VOLUMES[@]}" ]; then
        echo "Nummer existiert nicht."
        exit 1
fi

# Zusammenfassung
SOURCE_VOLUME="${VOLUMES[$((SOURCE_SELECTION-1))]}"

# Container vom Quell-Volume stoppen
SOURCE_CONTAINERS=$(docker ps -q --filter "volume=${SOURCE_VOLUME}")
if [ -n "$SOURCE_CONTAINERS" ]; then
    echo -e "${YELLOW}Stoppe Container, die das Quell-Volume verwenden...${NC}"
    docker stop $SOURCE_CONTAINERS
fi
echo -e "${GREEN}Quell-Volume: ${SOURCE_VOLUME}${NC}"
echo -e "${GREEN}Ziel-Volume: ${TARGET_VOLUME}${NC}"
echo
echo -ne "${YELLOW}Möchten Sie die Daten jetzt übertragen? (j/n): ${NC}"
read -r CONFIRM
if [[ "$CONFIRM" != "j" ]]; then
    echo "Abgebrochen."
    exit 0
fi

# Daten übertragen
echo -e "${CYAN}Daten werden übertragen...${NC}"
docker run --rm -v "${SOURCE_VOLUME}:/from" -v "${TARGET_VOLUME}:/to" alpine sh -c "cd /from && cp -a . /to/"
echo -e "${GREEN}Datenübertragung abgeschlossen!${NC}"

# Überprüfen, ob Daten übertragen wurden
echo -e "${CYAN}Überprüfe Datenübertragung...${NC}"
docker run --rm -v "${SOURCE_VOLUME}:/from" alpine sh -c "find /from | wc -l"
docker run --rm -v "${TARGET_VOLUME}:/to" alpine sh -c "find /to | wc -l"
echo -e "${GREEN}Überprüfung abgeschlossen!${NC}"

# Optional: Quell-Volume löschen
echo -ne "${YELLOW}Möchten Sie das Quell-Volume löschen? (j/n): ${NC}"
read -r DELETE_CONFIRM
if [[ "$DELETE_CONFIRM" == "j" ]]; then
    docker volume rm "${SOURCE_VOLUME}"
    echo -e "${GREEN}Quell-Volume gelöscht!${NC}"
else
    echo "Quell-Volume bleibt erhalten."
fi