#!/bin/zsh

# Diretórios
SRC_DIR="./src"
TB_DIR="./testbench"
VCD_DIR="./vcd"
mkdir -p $VCD_DIR

# Stop time padrão
STOP_TIME="1200us"

echo "=== Escolha o que deseja simular ==="
echo "1) Componentes (Motor e Porta)"
echo "2) Elevador"
echo "3) Escalonador"
echo "4) Top-level (Simulação final completa)"
echo "5) Todos (Roda todos os testes, 1 a 4, em sequência)"
read "?Digite a opção [1-5]: " OPC

# Função para compilar componentes base
compile_components() {
    echo "Compilando Componentes (Motor, Porta, SeteSeg)..."
    ghdl -a $SRC_DIR/components/Motor.vhd
    ghdl -a $SRC_DIR/components/Porta.vhd
    ghdl -a $SRC_DIR/components/SeteSeg.vhd
}

# Função para compilar todos os módulos para o Top-level
compile_all_modules() {
    compile_components
    echo "Compilando Controllers (Elevador, Escalonador)..."
    ghdl -a $SRC_DIR/controllers/Elevador.vhd
    ghdl -a $SRC_DIR/controllers/Escalonador.vhd
    echo "Compilando Top-level..."
    ghdl -a $SRC_DIR/top/Top.vhd
}

# Função para rodar simulação e salvar log
run_sim() {
    local tb=$1
    local LOG_FILE_PATH="$VCD_DIR/${tb}_output.txt"
    
    echo "Rodando simulação de $tb..."
    echo "A saída dos 'reports' será salva em: $LOG_FILE_PATH"
    
    # Redireciona stdout (>) E stderr (2>&1) para o arquivo de log
    ghdl -r $tb --vcd=$VCD_DIR/${tb}.vcd --stop-time=$STOP_TIME > $LOG_FILE_PATH 2>&1
}

case $OPC in
    1)
        # Testa SÓ os componentes
        echo "Limpando compilações..."
        ghdl --clean
        compile_components
        
        echo "Compilando testbenches dos componentes..."
        ghdl -a $TB_DIR/tb_motor.vhd
        ghdl -a $TB_DIR/tb_porta.vhd
        ghdl -e tb_motor
        ghdl -e tb_porta
        
        run_sim tb_motor
        run_sim tb_porta
        ;;
    2)
        # Testa SÓ o Elevador
        echo "Limpando compilações..."
        ghdl --clean
        compile_components # Compila dependências (Motor, Porta, SeteSeg)
        
        echo "Compilando Elevador e seu testbench..."
        ghdl -a $SRC_DIR/controllers/Elevador.vhd
        ghdl -a $TB_DIR/tb_elevador.vhd
        ghdl -e tb_elevador
        
        run_sim tb_elevador
        ;;
    3)
        # Testa SÓ o Escalonador
        echo "Limpando compilações..."
        ghdl --clean
        
        echo "Compilando Escalonador e seu testbench..."
        ghdl -a $SRC_DIR/controllers/Escalonador.vhd
        ghdl -a $TB_DIR/tb_escalonador.vhd
        ghdl -e tb_escalonador
        
        run_sim tb_escalonador
        ;;
    4)
        # Testa o sistema COMPLETO (Top-level)
        echo "Limpando compilações..."
        ghdl --clean
        compile_all_modules # Compila todos os módulos
        
        echo "Compilando Testbench (tb_top)..."
        ghdl -a $TB_DIR/tb_top.vhd
        ghdl -e tb_top
        
        run_sim tb_top
        ;;
    5)
        # Roda TODOS os testes, um por um.
        echo "--- Executando Teste 1: Componentes ---"
        ./testbench.sh <<< "1" > /dev/null # Roda a opção 1 em silêncio
        
        echo "--- Executando Teste 2: Elevador ---"
        ./testbench.sh <<< "2" > /dev/null # Roda a opção 2 em silêncio
        
        echo "--- Executando Teste 3: Escalonador ---"
        ./testbench.sh <<< "3" > /dev/null # Roda a opção 3 em silêncio
        
        echo "--- Executando Teste 4: Top-level ---"
        ./testbench.sh <<< "4" # Roda a opção 4 e mostra a saída
        ;;
    *)
        echo "Opção inválida!"
        exit 1
        ;;
esac

echo "=== Simulação concluída ==="
echo "Logs de saída foram salvos em $VCD_DIR/"