import asyncio
from urllib.parse import parse_qs
from aiohttp import web

from helpers import local_db_wrapper, Summary

__all__ = [
    'clients_api',
    'history_api',
]


@asyncio.coroutine
def clients_api(request):
    qs = parse_qs(request.query_string)
    qs_request = qs.get('q')
    if qs_request:
        qs_request = qs_request[0]
        query = "SELECT name FROM client WHERE lower(substr(name, 0, %s)) = lower(%s);"
        fetch = yield from local_db_wrapper(query, parameters=(len(qs_request) + 1, qs_request,))
    else:
        query = "SELECT name FROM client;"
        fetch = yield from local_db_wrapper(query)
    clients_list = [client[0] for client in fetch]
    return web.json_response(data={'clients': clients_list})


@asyncio.coroutine
def history_api(request):
    qs = parse_qs(request.query_string)
    qs_request = qs.get('q')
    if not qs_request:
        return web.json_response(status=400)

    result = yield from local_db_wrapper('SELECT asr_last, acd_last, duration_last, calls_last, '
                                         ' EXTRACT(EPOCH  from last_update) * 1000'
                                         ' FROM client_summary '
                                         ' INNER JOIN client ON client_summary.client_id = client.id'
                                         ' WHERE client.name = %s ORDER by last_update DESC',
                                         parameters=(qs_request[0], ))

    summaries = [Summary(*row) for row in result]
    response = dict(
        asr=[[summary.last_update, summary.asr_last] for summary in summaries],
        acd=[[summary.last_update, summary.acd_last] for summary in summaries],
        c_last=[[summary.last_update, summary.calls_last] for summary in summaries],
        d_last=[[summary.last_update, summary.duration_last.seconds] for summary in summaries],
    )
    return web.json_response(data=response)
