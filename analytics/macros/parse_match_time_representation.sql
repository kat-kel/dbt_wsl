{% macro match_time_part(column_name, part) %}
  {{ return(adapter.dispatch('match_time_part')(column_name, part)) }}
{% endmacro %}

{% macro default__match_time_part(column_name, part) %}
  split_part(replace({{ column_name }}, '''', ''), '+', {{ part }})
{% endmacro %}

{% macro clickhouse__match_time_part(column_name, part) %}
  splitByChar('+', replaceAll({{ column_name }}, '''', ''))[{{ part }}]
{% endmacro %}

{% macro match_regulation_time(column_name) %}
    cast({{ match_time_part(column_name, 1) }} as integer)
{% endmacro %}

{% macro match_added_time(column_name) %}
  case
    when {{ column_name }} is not null
    then coalesce(cast(nullif({{ match_time_part(column_name, 2) }}, '') as integer), 0)
  end
{% endmacro %}


{% macro match_clock_seconds(column_name) %}
  cast({{ dbt.split_part(column_name, "':'", 1) }} AS integer) * 60
  + cast({{ dbt.split_part(column_name, "':'", 2) }} AS integer)
{% endmacro %}

{% macro match_clock_minute(column_name) %}
  cast({{ dbt.split_part(column_name, "':'", 1) }} AS integer) + 1
{% endmacro %}

{% macro regulation_time_from_minute(minute_column, half_column) %}
  case
    when {{ minute_column }} <= 45 * {{ half_column }} then {{ minute_column }}
    when {{ minute_column }} > 45 * {{ half_column }} then 45 * {{ half_column }}
  end
{% endmacro %}

{% macro injury_time_from_minute(minute_column, half_column) %}
  case
    when {{ minute_column }} <= 45 * {{ half_column }} then 0
    when {{ minute_column }} > 45 * {{ half_column }} then {{ minute_column }} - 45 * {{ half_column }}
  end
{% endmacro %}