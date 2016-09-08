import aiopg
import asyncio
from collections import namedtuple

from settings import DB_GF, DB_LOCAL


def route(method, path, handler, name=None, expect_handler=None):
    return dict(
        method=method,
        path=path,
        handler=handler,
        name=name,
        expect_handler=expect_handler
    )


@asyncio.coroutine
def psql_db_wrapper(query, parameters=None, db_settings=None):
    assert isinstance(db_settings, dict)
    conn = yield from aiopg.connect(**db_settings)
    try:
        cur = yield from conn.cursor()
        query = yield from cur.mogrify(query, parameters=parameters)
        query = query.decode()
        yield from cur.execute(query)
        if query.lower().startswith('insert'):
            return
        ret = yield from cur.fetchall()
    finally:
        yield from conn.close()
    return ret


@asyncio.coroutine
def main_db_wrapper(query, parameters=None):
    return psql_db_wrapper(query, parameters=parameters, db_settings=DB_GF)


@asyncio.coroutine
def local_db_wrapper(query, parameters=None):
    return psql_db_wrapper(query, parameters=parameters, db_settings=DB_LOCAL)

Instance_from_gf = namedtuple('Instance', ['name',
                                           'calls_long_last',
                                           'calls_last',
                                           'duration_last',
                                           'expires',
                                           'acd_last',
                                           'asr_last',
                                           'last_update',
                                           ])

Instance = namedtuple('Instance', ['name', 'calls_long_last', 'calls_last', 'duration_last', 'cnt'])
Issue = namedtuple('Issue', ['id', 'body', 'closed', 'date', 'username', 'updated'])
Comment = namedtuple('Comment', ['id', 'author', 'body', 'date'])
Summary = namedtuple('Summary', ['asr_last', 'acd_last', 'duration_last', 'calls_last',  'last_update'])
