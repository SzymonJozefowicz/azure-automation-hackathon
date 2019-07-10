from datetime import timedelta

import airflow
from airflow.models import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.dummy_operator import DummyOperator

args = {
    'owner': 'airflow',
    'start_date': airflow.utils.dates.days_ago(2),
}

dag = DAG(
    dag_id='azure_automation_sample',
    default_args=args,
    schedule_interval='0 0 * * *',
    dagrun_timeout=timedelta(minutes=60),
)

start = DummyOperator(
    task_id='start',
    dag=dag,
)

vm_run = BashOperator(
    task_id='vm_run',
    bash_command='az --help ',
    dag=dag,
)

end = DummyOperator(
    task_id='end',
    dag=dag,
)

start >> vm_run >> stop

