# Run dbt commands for the analytics project from the repo root.
#
# Recipes run inside analytics/ because profiles.yml points DuckDB at the
# relative path `warehouse.duckdb`; running dbt from the root with
# --project-dir would create a separate, empty database here instead.

set working-directory := "analytics"
set positional-arguments

# Always use the project's .venv dbt (pinned in uv.lock), even in shells
# where direnv hasn't activated it.
dbt := justfile_directory() / ".venv/bin/dbt"
python := justfile_directory() / ".venv/bin/python"

# List available recipes
default:
    @just --list

# Load the raw CSVs into the warehouse's `raw` schema
ingestion:
    cd "{{ justfile_directory() }}" && {{ python }} -c "import duckdb; duckdb.connect('analytics/warehouse.duckdb').execute(open('ingestion.sql').read())"
    {{ python }} -c "import duckdb; duckdb.connect('warehouse.duckdb', read_only=True).sql('select schema_name as schema, table_name as name, estimated_size as rows from duckdb_tables() order by 1, 2').show()"

# Run any dbt command, e.g. `just dbt ls --select my_first_dbt_model`
dbt *args:
    {{ dbt }} "$@"

# Check the DuckDB connection
debug *args:
    {{ dbt }} debug "$@"

# Parse the project and report deprecations
parse *args:
    {{ dbt }} parse --show-all-deprecations "$@"

# Compile models
compile *args:
    {{ dbt }} compile "$@"

# Build seeds, models, snapshots and tests
build *args:
    {{ dbt }} build "$@"

# Run models
run *args:
    {{ dbt }} run "$@"

# Test models
test *args:
    {{ dbt }} test "$@"

# Preview a model's rows, e.g. `just show my_second_dbt_model`
show model *args:
    {{ dbt }} show --select "$@"

# Generate the docs site, including column-level lineage
docs:
    # `docs generate` rejects --static-analysis, so compile in strict mode
    # first and have generate reuse that compile.
    {{ dbt }} compile --static-analysis strict --generate-info-schema
    {{ dbt }} docs generate --no-compile

# Generate the docs, then serve them at http://127.0.0.1:8580
serve *args: docs
    {{ dbt }} docs serve "$@"

# Remove target/ and dbt_packages/
clean:
    {{ dbt }} clean
