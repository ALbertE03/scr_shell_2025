#!/bin/bash

echo "🐳 SCR Shell 2025 - Docker Helper"
echo "=================================="

case "$1" in
    "build")
        echo "Construyendo imagen Docker..."
        docker build -t scr-shell .
        ;;
    "run")
        echo "Ejecutando shell en Docker..."
        docker run -it --rm scr-shell
        ;;
    "run-interactive")
        echo "Ejecutando shell interactivo con volumen montado..."
        docker run -it --rm -v "$(pwd)":/app scr-shell
        ;;
    "dev")
        echo "Iniciando contenedor de desarrollo..."
        docker-compose up shell-dev
        ;;
    "shell")
        echo "Iniciando shell normal..."
        docker-compose up shell
        ;;
    "test")
        echo "Ejecutando tests en Docker..."
        docker run -it --rm -v "$(pwd)":/app scr-shell python3 tests/main.py
        ;;
    "clean")
        echo "Limpiando contenedores e imágenes..."
        docker-compose down
        docker rmi scr-shell 2>/dev/null || true
        ;;
    *)
        echo "Uso: $0 {build|run|run-interactive|dev|shell|test|clean}"
        echo ""
        echo "Comandos disponibles:"
        echo "  build           - Construir la imagen Docker"
        echo "  run             - Ejecutar el shell (sin volumen)"
        echo "  run-interactive - Ejecutar el shell con código local montado"
        echo "  dev             - Iniciar contenedor de desarrollo con bash"
        echo "  shell           - Iniciar el shell usando docker-compose"
        echo "  test            - Ejecutar tests en Docker"
        echo "  clean           - Limpiar contenedores e imágenes"
        ;;
esac
