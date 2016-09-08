import asyncio

from helpers import main_db_wrapper, Instance_from_gf, local_db_wrapper
from settings import QUERY


@asyncio.coroutine
def run_with_interval():
    while True:
        yield from main_fetcher()
        yield from asyncio.sleep(60*10)


@asyncio.coroutine
def main_fetcher():
    with open(QUERY['INSTANCE_QUERY_GF'], 'r') as get_vips_query:
        fetch = yield from main_db_wrapper(get_vips_query.read())
        instances = [Instance_from_gf(*row) for row in fetch]
        instance_names = ','.join([instance.name for instance in instances])
        yield from local_db_wrapper('SELECT * FROM client_insert_safe_array(%s)', parameters=(instance_names,))
        for instance in instances:
            summary_query = 'SELECT * FROM insert_summary(%s, %s, %s, %s, %s, %s, %s)'
            yield from local_db_wrapper(summary_query, parameters=(instance.name,
                                                                   instance.calls_long_last,
                                                                   instance.calls_last,
                                                                   instance.duration_last,
                                                                   instance.acd_last,
                                                                   instance.asr_last,
                                                                   instance.last_update
                                                                   ))

