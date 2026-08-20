"""Validate and load the Olist CSV source files into Postgres."""

import csv
import logging
import os
from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook


CSV_PATH = "/usr/local/airflow/include/Olist-dataset"
POSTGRES_CONN = "postgres_conn"

FILES_TO_UPLOAD = {
    "customers.csv": "customers",
    "orders.csv": "orders",
    "products.csv": "products",
}


def validate_file(file_name: str) -> int:
    """Ensure a source file has a usable header and structurally valid rows."""

    file_path = os.path.join(CSV_PATH, file_name)

    if not os.path.isfile(file_path):
        raise FileNotFoundError(
            f"Olist file not found: {file_path}"
        )

    with open(
        file_path,
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as source_file:

        reader = csv.reader(source_file)

        try:
            columns = next(reader)

        except StopIteration as error:
            raise ValueError(
                f"Olist file is empty: {file_path}"
            ) from error

        if not columns or any(
            not column.strip() for column in columns
        ):
            raise ValueError(
                f"Olist file has an invalid header: {file_path}"
            )

        row_count = 0

        for line_number, row in enumerate(reader, start=2):

            if len(row) != len(columns):
                raise ValueError(
                    f"Invalid column count in {file_name} "
                    f"at line {line_number}: "
                    f"expected {len(columns)}, got {len(row)}"
                )

            row_count += 1

    if row_count == 0:
        raise ValueError(
            f"Olist file has no data rows: {file_path}"
        )

    logging.info(
        "Validated %s with %s data rows",
        file_name,
        row_count,
    )

    return row_count


def upload_files(
    file_name: str,
    table_name: str
) -> None:

    """Load a validated CSV file into Bronze."""

    file_path = os.path.join(
        CSV_PATH,
        file_name
    )

    with open(
        file_path,
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as source_file:

        columns = next(csv.reader(source_file))

    create_table_sql = f"""
        CREATE SCHEMA IF NOT EXISTS bronze;

        CREATE TABLE IF NOT EXISTS bronze."{table_name}" (
            {
                ", ".join(
                    f'"{column}" TEXT'
                    for column in columns
                )
            }
        );

        TRUNCATE TABLE bronze."{table_name}";
    """

    hook = PostgresHook(
        postgres_conn_id=POSTGRES_CONN
    )

    hook.run(create_table_sql)

    hook.copy_expert(
        sql=(
            f'COPY bronze."{table_name}" '
            f"FROM STDIN "
            f"WITH CSV HEADER DELIMITER ','"
        ),
        filename=file_path,
    )

    logging.info(
        "Loaded %s into bronze.%s",
        file_name,
        table_name,
    )


with DAG(
    dag_id="Ecommerace_DAG",
    description=(
        "Validate and load Olist data "
        "from the include directory"
    ),
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["olist", "ingestion", "dbt"],
) as dag:

    load_tasks = []

    for file_name, table_name in FILES_TO_UPLOAD.items():

        dataset_name = table_name.lower()

        validate_task = PythonOperator(
            task_id=f"validate_{dataset_name}",
            python_callable=validate_file,
            op_kwargs={
                "file_name": file_name
            },
        )

        load_task = PythonOperator(
            task_id=f"load_{dataset_name}",
            python_callable=upload_files,
            op_kwargs={
                "file_name": file_name,
                "table_name": table_name,
            },
        )

        validate_task >> load_task

        load_tasks.append(load_task)

    dbt_run = BashOperator(
        task_id="Transformations_with_DBT",
        bash_command="""
            cd /usr/local/airflow/include/dbt/ecommerace_dbt &&
            dbt run --profiles-dir .
        """,
    )

    dbt_test_task = BashOperator(
        task_id='Run_dbt_tests',
        bash_command="""
            cd /usr/local/airflow/include/dbt/ecommerace_dbt &&
            dbt test --profiles-dir .
        """,
    )

    load_tasks >> dbt_run >> dbt_test_task