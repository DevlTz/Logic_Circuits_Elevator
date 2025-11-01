#!/bin/zsh

# Diretórios
SRC_DIR="./src"
TB_DIR="./testbench"
VCD_DIR="./vcd"
mkdir -p $VCD_DIR

# Stop time padrão
STOP_TIME="10us"

echo "=== Escolha o que deseja simular ==="
echo "1) Componentes (Motor e Porta)"
echo "2) Elevador"
echo "3) Escalonador"
echo "4) Todos"
read "?Digite a opção [1-4]: " OPC

# Função para compilar componentes
compile_components() {
    echo "Compilando Motor e Porta..."
    ghdl -a $SRC_DIR/components/Motor.vhd
    ghdl -a $SRC_DIR/components/Porta.vhd
    ghdl -a $TB_DIR/tb_motor.vhd
    ghdl -a $TB_DIR/tb_porta.vhd
    ghdl -e tb_motor
    ghdl -e tb_porta
}

# Função para compilar Elevador
compile_elevador() {
    echo "Compilando Elevador..."
    ghdl -a $SRC_DIR/components/Motor.vhd
    ghdl -a $SRC_DIR/components/Porta.vhd
    ghdl -a $SRC_DIR/controllers/Elevador.vhd
    ghdl -a $TB_DIR/tb_elevador.vhd
    ghdl -e tb_elevador
}

# Função para compilar Escalonador
compile_escalonador() {
    echo "Compilando Escalonador..."
    ghdl -a $SRC_DIR/controllers/Escalonador.vhd
    ghdl -a $TB_DIR/tb_escalonador.vhd
    ghdl -e tb_escalonador
}

# Função para rodar simulação e gerar VCD/TXT
run_sim() {
    local tb=$1
    echo "Rodando simulação de $tb..."
    ghdl -r $tb --vcd=$VCD_DIR/${tb}.vcd --stop-time=$STOP_TIME
    txt_file=$VCD_DIR/${tb}.txt
    echo "Convertendo VCD para TXT -> $txt_file"
    perl ~/vcd2txt-0.1/vcd2txt.pl $VCD_DIR/${tb}.vcd > $txt_file
}

case $OPC in
    1)
        compile_components
        run_sim tb_motor
        run_sim tb_porta
        ;;
    2)
        compile_elevador
        run_sim tb_elevador
        ;;
    3)
        compile_escalonador
        run_sim tb_escalonador
        ;;
    4)
        compile_components
        compile_elevador
        compile_escalonador
        run_sim tb_motor
        run_sim tb_porta
        run_sim tb_elevador
        run_sim tb_escalonador
        ;;
    *)
        echo "Opção inválida!"
        exit 1
        ;;
esac

echo "=== Simulação concluída ==="
