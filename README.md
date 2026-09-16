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

O repositório possui os seguintes workflows:

```text
.github/workflows/
├── full-build.yaml
└── smart-user-and-full-build.yaml
```

---

# 1. Full Build

Arquivo:

```text
.github/workflows/full-build.yaml
```

O workflow **IDzEE Build** executa uma compilação completa da aplicação utilizando o DBB.

Ele pode ser iniciado manualmente pelo menu **Actions > IDzEE Build > Run workflow**.

> O gatilho automático por `push` está desativado neste workflow (`on` comentado).

## Fluxo

```text
Execução manual
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

# 2. Smart User and Full Build

Arquivo:

```text
.github/workflows/smart-user-and-full-build.yaml
```

O workflow **IDzEE Smart User and Full Build** analisa os arquivos modificados no commit e decide automaticamente entre **User Build**, **Full Build** ou nenhuma compilação.

Ele também pode ser executado manualmente, permitindo selecionar:

```text
auto
full
user
```

No modo `auto`, a própria esteira escolhe o tipo de build.

> O gatilho automático por `push` está desativado neste workflow (`on` comentado).

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

O workflow considera diretamente como fontes compiláveis:

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

# Comparativo dos workflows

| Característica | Full Build | Smart User+Full |
|---|:---:|:---:|
| Compila toda a aplicação | Sim | Quando necessário |
| Detecta arquivos alterados | Não | Sim |
| Executa User Build | Não | Sim |
| Decide estratégia automaticamente | Não | Sim |
| Execução manual | Sim | Sim |
| Execução automática em `push` para `main` | Não | Não |

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

# Vantagens da Pipeline

A arquitetura **GitHub + GitHub Actions + RSE API + IBM DBB** moderniza o processo de desenvolvimento e build no z/OS, utilizando Git como SCM e separando claramente versionamento, orquestração e compilação.

## Principais vantagens

* **Git como fonte de verdade:** código, histórico, branches e versões são gerenciados no GitHub, aproximando o desenvolvimento mainframe das práticas utilizadas em ambientes distribuídos.

* **Pipeline as Code:** toda a lógica de CI/CD fica definida em YAML e versionada junto ao projeto, facilitando manutenção, auditoria e evolução da esteira.

* **Build inteligente e incremental:** os Smart Builds identificam as alterações do commit e decidem automaticamente entre User Build, Impact Build, Full Build ou nenhuma compilação.

* **Transferência incremental:** em builds incrementais, somente os arquivos modificados são enviados do runner para o USS, reduzindo transferência e processamento desnecessários.

* **Rastreabilidade:** cada execução pode ser associada diretamente ao commit, branch, arquivos alterados, tipo de build e resultado da compilação.

* **Análise de dependências:** o DBB permite utilizar Impact Analysis, recompilando apenas os componentes afetados por alterações em dependências como copybooks.

* **Integração DevOps:** Pull Requests, Code Review, branches, automações e futuras etapas de testes, quality gates e deploy podem fazer parte do mesmo fluxo.

* **Separação de responsabilidades:** Git/GitHub gerencia o código, GitHub Actions orquestra a esteira e o DBB executa o processo de build no z/OS.

---

# Vantagens em relação a um SCM clássico

Em um SCM mainframe tradicional, como o Endevor, diversas responsabilidades do ciclo de desenvolvimento ficam concentradas em uma solução específica do ambiente mainframe.

Nesta arquitetura, essas responsabilidades são desacopladas:

| Responsabilidade               | Arquitetura proposta        |
| ------------------------------ | --------------------------- |
| Versionamento                  | Git / GitHub                |
| Branching e merge              | Git                         |
| Code Review                    | Pull Requests               |
| CI/CD                          | GitHub Actions              |
| Build                          | IBM DBB                     |
| Dependências / Impact Analysis | IBM DBB                     |
| Compilação                     | Ferramentas nativas do z/OS |
| Segurança                      | RACF                        |

---

# Resumo

Os dois workflows atendem objetivos diferentes:

**`full-build.yaml`** fornece um fluxo simples e previsível para reconstrução completa da aplicação.

**`smart-user-and-full-build.yaml`** adiciona inteligência à pipeline, analisando as mudanças do Git e escolhendo entre User Build, Full Build ou nenhuma compilação.
