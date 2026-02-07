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
echo -e "   Docker Container Updater"
echo -e "${RED}==============================${NC}"
echo


# Überprüfen auf vorhandene Container
mapfile -t CONTAINERS < <(docker ps -a --format "{{.Names}}")

if [ ${#CONTAINERS[@]} -eq 0 ]; then
        echo "Keine Container gefunden."
        exit 0
fi

# Container auflisten
echo -e "${CYAN}Verfügbare Container:${NC}"
echo " 0) [Mehrere Container auswählen]"
for i in "${!CONTAINERS[@]}"; do

    # Containername abrufen
    CONTAINER="${CONTAINERS[$i]}"
    printf " %d) %s " $((i+1)) "${CONTAINER}"
	echo

done

# Benutzereingabe
echo
echo -ne "${CYAN}Container auswählen (Nummer): ${NC}"
read -r SELECTION


## Validierung
# Überprüfen, ob Eingabe eine Zahl ist
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
        echo "Ungültige Eingabe. Bitte eine Zahl eingeben."
        exit 1
fi
# Überprüfen, ob Zahl im gültigen Bereich ist
if [ "$SELECTION" -gt "${#CONTAINERS[@]}" ]; then
        echo "Nummer existiert nicht."
        exit 1
fi


# Auswahl auflösen
if [ "$SELECTION" -eq 0 ]; then
    echo -ne "${CYAN}Geben Sie die Nummern der Container ein, die Sie aktualisieren möchten (z.B. 1 3 5): ${NC}"
    read -r -a MULTI_SELECTIONS
    SELECTED_CONTAINERS=()
    for SEL in "${MULTI_SELECTIONS[@]}"; do
        if ! [[ "$SEL" =~ ^[0-9]+$ ]] || [ "$SEL" -lt 1 ] || [ "$SEL" -gt "${#CONTAINERS[@]}" ]; then
            echo "Ungültige Auswahl: $SEL. Überspringe."
            continue
        fi
        INDEX=$((SEL-1))
        SELECTED_CONTAINERS+=("${CONTAINERS[$INDEX]}")
    done
else
    INDEX=$((SELECTION-1))
    SELECTED_CONTAINERS=("${CONTAINERS[$INDEX]}")
fi

echo
echo -e "${CYAN}Ausgewählt:${NC}"
for c in "${SELECTED_CONTAINERS[@]}"; do
        echo " - $c"
done

echo
echo -e "${CYAN}Zugehörige Images:${NC}"
for c in "${SELECTED_CONTAINERS[@]}"; do
        IMAGE=$(docker inspect --format='{{.Config.Image}}' "$c")
        echo " - $c → $IMAGE"
done


# Images pullen
echo
echo -e "${CYAN}Pulling images...${NC}"

for c in "${SELECTED_CONTAINERS[@]}"; do
    PROJECT=$(docker inspect "$c" --format '{{ index .Config.Labels "com.docker.compose.project" }}')
    STACK_DIR="$BASE_DIR/$PROJECT"

    if [ ! -f "$STACK_DIR/docker-compose.yml" ]; then
        echo " - $c: kein docker-compose.yml gefunden, übersprungen."
        continue
    fi

    echo " - $c: docker compose pull"
    docker compose -f "$STACK_DIR/docker-compose.yml" pull

    echo " - $c: docker compose up -d"
    docker compose -f "$STACK_DIR/docker-compose.yml" up -d --no-build
done
