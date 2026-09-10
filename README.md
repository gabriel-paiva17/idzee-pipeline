# IDzEE Pipeline — GitHub Actions + DBB

Este repositório contém workflows do **GitHub Actions** para automatizar a compilação de aplicações no **z/OS** utilizando **IBM Dependency Based Build (DBB)**.

A arquitetura utiliza um **GitHub Actions self-hosted runner**, que se comunica com o z/OS por **HTTPS**, por meio do **RSE API / Zowe CLI**. As credenciais do usuário RACF utilizado pela esteira são armazenadas como **GitHub Secrets**.

## Arquitetura resumida

```text
GitHub Repository
       |
       | Checkout
       v
GitHub Actions
       |
       v
Self-hosted Runner
       |
       | HTTPS / RSE API
       v
     z/OS USS
       |
       v
      DBB
       |
       v
Compilação / Link-edit
```

O repositório possui dois workflows principais:

```text
.github/workflows/
├── full-build.yaml
└── smart-build.yaml
```

---

# 1. Full Build

Arquivo:

```text
.github/workflows/full-build.yaml
```

O workflow **IDzEE Build** executa uma compilação completa da aplicação utilizando o DBB.

Ele pode ser iniciado automaticamente por um `push` na branch `main` ou manualmente pelo menu **Actions > IDzEE Build > Run workflow**.

## Fluxo

```text
Push / execução manual
        |
        v
Checkout do repositório
        |
        v
Validação do Runner
        |
        v
Preparação do workspace USS
        |
        v
Upload do repositório para o z/OS
        |
        v
Inicialização do Git no USS
        |
        v
DBB Full Build
```

O comando principal executado no z/OS é equivalente a:

```bash
$DBB_HOME/bin/dbb build full \
  --hlq <USER>.DBB
```

## Quando utilizar

O Full Build é indicado quando é necessário reconstruir toda a aplicação, por exemplo:

- primeira compilação da aplicação;
- alterações estruturais ou de configuração;
- alterações que podem afetar grande parte da aplicação;
- validação completa do projeto;
- fallback quando não é possível determinar com segurança quais programas foram impactados.

---

# 2. Smart Build

Arquivo:

```text
.github/workflows/smart-build.yaml
```

O workflow **IDzEE Smart Build** analisa os arquivos modificados no commit e decide automaticamente qual estratégia de compilação utilizar.

Ele também pode ser executado manualmente, permitindo selecionar:

```text
auto
full
user
```

No modo `auto`, a própria esteira escolhe o tipo de build.

## Lógica de decisão

```text
Arquivos alterados
       |
       v
Analisar alterações
       |
       +-- Configuração DBB alterada? ------> FULL BUILD
       |
       +-- Copybook (.cpy) alterado? -------> FULL BUILD (*)
       |
       +-- Mais de 10 fontes? --------------> FULL BUILD
       |
       +-- 1 a 10 fontes? ------------------> USER BUILD
       |
       +-- Nenhum fonte relevante ----------> SEM BUILD
```

(*) Atualmente, alterações em copybooks utilizam Full Build como fallback seguro. A evolução prevista é utilizar o **DBB Impact Analysis** para localizar e recompilar somente os programas dependentes.

## Arquivos considerados compiláveis

O Smart Build considera diretamente como fontes compiláveis:

```text
.cbl
.cbcw
.bms
```

Copybooks são identificados separadamente:

```text
.cpy
```

## Exemplos

| Alteração | Estratégia |
|---|---|
| `README.md` | Nenhum build |
| `cobol/programa.cbl` | User Build |
| `cobol/programa.cbcw` | User Build |
| `bms/tela.bms` | User Build |
| 5 fontes compiláveis | User Build dos 5 arquivos |
| Mais de 10 fontes | Full Build |
| `copybook/cliente.cpy` | Full Build |
| `dbb-app.yaml` | Full Build |
| `dbb-build.yaml` | Full Build |

Quando vários fontes são modificados, o workflow percorre a lista de arquivos e executa um **User Build para cada fonte alterado**.

Exemplo:

```text
programa1.cbl
programa2.cbcw
tela.bms
```

Resulta conceitualmente em:

```text
User Build -> programa1.cbl
User Build -> programa2.cbcw
User Build -> tela.bms
```

---

# Full Build x Smart Build

| Característica | Full Build | Smart Build |
|---|---:|---:|
| Compila toda a aplicação | Sim | Quando necessário |
| Detecta arquivos alterados | Não | Sim |
| Executa User Build | Não | Sim |
| Suporta vários fontes alterados | Sim, via Full Build | Sim, individualmente |
| Detecta copybook alterado | Não necessário | Sim |
| Decide estratégia automaticamente | Não | Sim |
| Execução manual | Sim | Sim |
| Execução em push para `main` | Sim | Sim |

O **Full Build** prioriza simplicidade e reconstrução completa. O **Smart Build** busca reduzir compilações desnecessárias e preparar a esteira para uma estratégia baseada em análise de impacto.

---

# Comunicação com o z/OS

Os workflows não executam o DBB diretamente no runner.

O fluxo é:

```text
GitHub
   |
   v
Self-hosted Runner
   |
   | Zowe CLI
   | HTTPS
   v
RSE API
   |
   v
z/OS UNIX System Services
   |
   v
DBB
```

O runner utiliza comandos do plugin **RSE API for Zowe CLI** para executar comandos UNIX e transferir o repositório para o USS.

Exemplos:

```bash
zowe rse-api-for-zowe-cli issue unix-shell
```

```bash
zowe rse-api-for-zowe-cli upload dir-to-uss
```

---

# Credenciais e GitHub Secrets

As informações de conexão com o z/OS não devem ser armazenadas diretamente nos arquivos YAML.

Os workflows utilizam os seguintes GitHub Secrets:

```text
ZOS_HOST
ZOS_PORT
ZOS_USER
ZOS_PASSWORD
```

Eles são disponibilizados ao workflow como variáveis de ambiente:

```yaml
env:
  ZOS_HOST: ${{ secrets.ZOS_HOST }}
  ZOS_PORT: ${{ secrets.ZOS_PORT }}
  ZOS_USER: ${{ secrets.ZOS_USER }}
  ZOS_PASSWORD: ${{ secrets.ZOS_PASSWORD }}
```

O `ZOS_USER` representa o **usuário RACF utilizado pela esteira/runner para se autenticar no z/OS**.

---

# Workspace no USS

O workspace é criado utilizando o usuário RACF da esteira.

Estrutura esperada:

```text
/u/<racf-user>/dbb/
├── logs/
└── idzee-pipeline/
```

O HLQ utilizado pelo DBB segue o padrão:

```text
<RACF_USER>.DBB
```

Exemplo:

```text
B027086.DBB
```

---

# Evolução prevista — Impact Analysis

Atualmente, uma alteração em `.cpy` provoca um **Full Build**, pois simplesmente compilar o copybook não seria suficiente.

Por exemplo:

```text
CUSTOMER.cpy
     |
     +-- PROGA.cbl
     +-- PROGB.cbl
     +-- PROGC.cbcw
```

Se `CUSTOMER.cpy` for alterado, os programas que dependem dele precisam ser identificados e recompilados.

A evolução do Smart Build é integrar o **DBB Impact Analysis**:

```text
Copybook alterado
       |
       v
DBB Impact Analysis
       |
       v
Identificação das dependências
       |
       v
Programas impactados
       |
       v
Build somente do necessário
```

Isso permitirá que a pipeline combine o versionamento em **Git/GitHub** com as capacidades de compilação e análise de dependências do **IBM DBB**, evitando Full Builds desnecessários.

---

# Resumo

Os dois workflows atendem objetivos diferentes:

**`full-build.yaml`** fornece um fluxo simples e previsível para reconstrução completa da aplicação.

**`smart-build.yaml`** adiciona inteligência à pipeline, analisando as mudanças do Git e escolhendo entre User Build, Full Build ou nenhuma compilação.

A estratégia permite evoluir gradualmente de uma pipeline de compilação completa para um modelo de **build incremental orientado pelas alterações e dependências da aplicação**.
