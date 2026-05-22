#!/data/data/com.termux/files/usr/bin/bash
CONFIG_FILE="$HOME/chronoshield-core/nodes.json"
TOKEN="CHRONO_SECURE_TOKEN_2026_XYZ"
Cyan=$'\e[0;36m'; Verde=$'\e[0;32m'; Amarillo=$'\e[0;33m'; Rojo=$'\e[0;31m'; Blanco=$'\e[0;37m'; Azul=$'\e[0;34m'; NC=$'\e[0m'

cargar_nodos() { NODOS=($(grep -o '"[^"]*"' "$CONFIG_FILE" | sed 's/"//g')); }
guardar_nodos() {
    local json="["
    for i in "${!NODOS[@]}"; do
        json+="\"${NODOS[$i]}\""
        if [ $i -lt $((${#NODOS[@]}-1)) ]; then json+=", "; fi
    done
    json+="]"
    echo "$json" > "$CONFIG_FILE"
}

ver_nodos() {
    clear
    echo "${Cyan}   ██████╗██╗  ██╗██████╗  ██████╗ ███╗   ██╗ ██████╗ 
  ██╔════╝██║  ██║██╔══██╗██╔═══██╗████╗  ██║██╔═══██╗
  ██║     ███████║██████╔╝██║   ██║██╔██╗ ██║██║   ██║
  ██║     ██╔══██║██╔══██╗██║   ██║██║╚██╗██║██║   ██║
  ╚██████╗██║  ██║██║  ██║╚██████╔╝██║ ╚████║╚██████╔╝
   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝${NC}"
    echo "${Amarillo}     [ PANEL INTERACTIVO MESH - CHRONOSHIELD v9.5.0 LTS ]${NC}"
    echo "${Azul}========================================================================${NC}"
    cargar_nodos
    for i in "${!NODOS[@]}"; do
        IP=${NODOS[$i]}
        RESPONSE=$(curl -s --max-time 1.2 -H "Authorization: Bearer $TOKEN" "http://$IP:8000/dashboard")
        if [ $? -eq 0 ] && [[ "$RESPONSE" == *"ONLINE"* ]]; then
            CPU=$(echo "$RESPONSE" | grep -o '"cpu_usage":"[^"]*"' | cut -d'"' -f4)
            RAM=$(echo "$RESPONSE" | grep -o '"ram_usage":"[^"]*"' | cut -d'"' -f4)
            echo "  ${Blanco}▶ NODO $(($i+1))${NC} [${Azul}$IP${NC}] -> ${Verde}[ONLINE]${NC} -> CPU: $CPU | RAM: $RAM"
        else
            echo "  ${Blanco}▶ NODO $(($i+1))${NC} [${Azul}$IP${NC}] -> ${Rojo}[OFFLINE / ACCESS DENIED]${NC}"
        fi
    done
    echo "${Azul}========================================================================${NC}"
}

menu() {
    echo "${Cyan}[+] DIRECTIVAS TÁCTICAS:${NC}"
    echo "  1. Auditar red (bmon)          2. Monitorear hilos (htop)"
    echo "  3. Administrar Nodos (JSON)    4. Ver Logs de Seguridad"
    echo "  5. PROPAGAR DESPLIEGUE OTA     6. Salir de la Consola"
    echo ""
    echo -ne "${Amarillo}Daniel, ingrese directiva: ${NC}"; read opt
    case $opt in
        1) bmon; bucle ;;
        2) htop; bucle ;;
        3) admin_nodos ;;
        4) echo -e "\n${Cyan}[*] Logs:${NC}"; tail -n 20 cluster_activity.log 2>/dev/null; echo -ne "\nEnter..."; read; bucle ;;
        5)
            echo -e "\n${Amarillo}[*] Propagando actualizacion cifrada...${NC}"
            for IP in "${NODOS[@]}"; do
                curl -s -X POST -H "Authorization: Bearer $TOKEN" --max-time 2 "http://$IP:8000/update" > /dev/null
                echo "Pulso enviado a $IP"
            done
            sleep 1; bucle ;;
        6) clear; exit 0 ;;
        *) bucle ;;
    esac
}

admin_nodos() {
    clear
    echo "--- GESTIÓN DE NODOS INTERACTIVA ---"
    cargar_nodos
    for i in "${!NODOS[@]}"; do echo "  $((i+1)). ${NODOS[$i]}"; done
    echo -e "\n  A) Agregar Nodo   E) Eliminar Nodo   V) Volver"
    echo -ne "\nSeleccione accion: "; read act
    if [[ "$act" =~ [aA] ]]; then
        echo -ne "IP/Host: "; read n_ip
        [ ! -z "$n_ip" ] && NODOS+=("$n_ip") && guardar_nodos
        admin_nodos
    elif [[ "$act" =~ [eE] ]]; then
        echo -ne "Numero de nodo a borrar: "; read num
        idx=$((num-1))
        if [ $idx -ge 0 ] && [ $idx -lt ${#NODOS[@]} ]; then
            unset 'NODOS[$idx]'; NODOS=("${NODOS[@]}"); guardar_nodos
        fi
        admin_nodos
    else bucle; fi
}

bucle() { ver_nodos; menu; }
bucle
