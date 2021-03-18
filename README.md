# Provenance for SPARQL queries via Query Rewiring: TPC-H benchmark

This is the source code repository of a experiment to study a method
for computing how-provenance for SPARQL via query rewriting.  This is
experiment is based on the TPC-H benchmark that is a well-known
synthetic SQL benchmark for analytic queries.  We translate the
dataset and the queries to RDF and SPARQL, respectively.

## Structure of this repository

```
datasets                     # The RDF and relational data
lib                          # Libraries required for the experiments
machines                     # Configuration files for our machine
plots                        # Plots generated from result analysis
queries                      # Benchmark queries
query_generators             # Code to generate queries
query_parameters             # Parameters generated from the qgen tool
query_parameter_templates    # Templates to be filled with the parameters
rakelib                      # Task definitions
results                      # Obtained results
sparql_examples              # SPARQL query templates
sql_examples                 # Some examples in SQL
task_status                  # Status of the executed tasks
```

## Preparing the environment

In this experiment we need three tools: LXD to install engines inside
containers, Ruby to automatize the execution of benchmarks, and
TripleProv.

### Setup LXD

We use LXD containers to facilitate the reproducibility of this
experiment.  Each of the multiple database instances is enclosed into
a separate container.

In our experiment we use a machine with Ubuntu 18.04 and install LXD
using `snap` (the recomended way these days).  Instructions to setup
LXD can be found in the [LXD
documentation](https://linuxcontainers.org/lxd/getting-started-cli/#installation).

### Setup Ruby

We use the Ruby programing language to automatize the execution of the
experiments.  We use the version 3.0.0 that can be installed with
`rbenv` and `rbenv-install`.  The following commands install Ruby 3.0.0.

```bash
sudo apt install -y \
  autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev \
  zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev \
  pigz
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
. ~/.bashrc
mkdir -p "$(rbenv root)"/plugins
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
rbenv install 3.0.0
```

After installing Ruby 3.0.0 it is needed to install some Ruby
packages.  This is done by running `bundle install` inside the root
folder of this repository.

## Preparing the data

We generate the datasets for this experiment using the `dbgen` tool
from the [official TPC-H experiment](http://www.tpc.org/tpch).  This
repository does not contain the code of the `dbgen` tool because right
restrictions.  We use the `dbgen` tool to generate multiple datasets
using scale factors: 0.01, 0.0178, 0.0316, 0.316, 0.563 and 1.  Each
dataset is stored into a folder using the scale factor as suffix.  For
instance, the folder for the scale factor 0.01 is called
`datasets/ds_tbl_0.01`.

After generating the data in the relational model we need to translate
this data to RDF.  The translation is done with the script
`tbl_to_rdf.rb`.  For instance, we generate the RDF dataset with scale
factor 0.01 with the following command:

```
lib/tbl_to_rdf.rb datasets/ds_tbl_0.01
mkdir datasets/ds_ttl_0.01
mv datasets/ds_tbl_0.01/*.ttl datasets/ds_ttl_0.01/
gzip datasets/ds_ttl_0.01/*.ttl
```

Observe that we store the resulting RDF dataset in the folder
`datasets/ds_ttl_0.01`.  This folder is assumed in the following
steeps of the experiment.

### Loading the data in a triple store

So far, we have created a dataset for each reification scheme.  We
next explain how to load each of these datasets in each triple store
engine.  We consider two triple store engines: Fuseki 3 (using TDB1)
and Virtuoso 7.

Datasets are loaded using [rake tasks](https://github.com/ruby/rake)
that are defined in `rakelib`.

Before loading the datasets, we need to create a container for each
engine.

```bash
rake task_status/done_create_fuseki_3_container
rake taks_status/done_create_virtuoso_7_container
```

These tasks above create two containers that serve as base to create
the container where to load each dataset.  The following tasks do the
load the datasets in copies of the aforementioned containers.  The
loading of datasets assumes that datasets are in the folder `datasets`
and have prefix `datasets/ds_ttl_`.

```bash
rake fuseki_tasks
rake virtuoso_tasks
```

## Generate the queries

Queries are generated with two tasks.  First we generate the
parameters using the `qgen` tool of the TPC-H benchmark, and then we
generate the queries filling our templates with these parameters.
These tasks are implemented in the following rake tasks:

```bash
rake parameters
rake queries
```

## Running the benchmark

An experiment workload is defined by a combination of a query template
and a triple store engine.  The execution of each query workload
generates a corresponding CSV file in the folder `results`.  All
experiment workloads are executed with the following rake task:

```bash
rake bench
```

Workloads can also be executed individually.  To list all experiment
workloads you can execute the following command:

```bash
rake --tasks task_status/done_run_bench
```

